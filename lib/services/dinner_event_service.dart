import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 預設每桌最大人數 ( fallback )
  static const int DEFAULT_MAX_PARTICIPANTS = 6;

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
  }) async {
    try {
      final docRef = _eventsCollection.doc();
      
      final participantIds = [creatorId];
      final participantStatus = {creatorId: 'confirmed'};
      
      final icebreakerQuestions = [
        '如果可以和世界上任何人共進晚餐，你會選誰？',
        '最近一次讓你開懷大笑的事情是什麼？',
        '你最喜歡的旅行經歷是什麼？',
      ];

      final event = DinnerEventModel(
        id: docRef.id,
        creatorId: creatorId,
        dateTime: dateTime,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        participantIds: participantIds,
        participantStatus: participantStatus,
        status: 'pending',
        createdAt: DateTime.now(),
        icebreakerQuestions: icebreakerQuestions,
      );

      await docRef.set(event.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('創建活動失敗: $e');
    }
  }

  /// 獲取單個活動詳情
  Future<DinnerEventModel?> getEvent(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('獲取活動詳情失敗: $e');
    }
  }

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 查詢用戶在參與者列表或候補名單中的活動
      // Firestore array-contains-any 限制最多 10 個值，這裡我們分開查或查兩次
      // 為了簡單，我們先查參與者，候補名單可能需要額外查詢或在應用層合併
      // 這裡暫時只查 participantIds，因為主要用途是看已報名活動
      // 如果要包含 waitlist，可以使用 Filter.or (如果 SDK 支援) 或分別查詢

      Query query = _eventsCollection.where('participantIds', arrayContains: userId);
      final participantSnapshot = await query.get();

      Query waitlistQuery = _eventsCollection.where('waitingListIds', arrayContains: userId);
      final waitlistSnapshot = await waitlistQuery.get();

      final Map<String, DinnerEventModel> eventsMap = {};

      for (var doc in participantSnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistSnapshot.docs) {
        if (!eventsMap.containsKey(doc.id)) {
           eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      var events = eventsMap.values.toList();

      if (status != null) {
        events = events.where((e) => e.status == status).toList();
      }
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<bool> _hasTimeConflict(String userId, DateTime newEventTime) async {
    // 假設晚餐活動持續 3 小時
    final newEventStart = newEventTime;
    final newEventEnd = newEventTime.add(const Duration(hours: 3));

    final userEvents = await getUserEvents(userId);

    for (var event in userEvents) {
      // 忽略已取消或完成的活動 (視業務邏輯而定，這裡假設只檢查未來的衝突)
      if (event.status == 'cancelled' || event.status == 'completed') continue;

      // 如果用戶在候補名單中，暫時不算衝突？或者也算？通常候補不算佔用時間，但為了避免重複排程，嚴格點可以算
      // 這裡我們只檢查已確認參與的 (participantIds)
      if (!event.participantIds.contains(userId)) continue;

      final eventStart = event.dateTime;
      final eventEnd = event.dateTime.add(const Duration(hours: 3));

      // 檢查時間重疊
      if (newEventStart.isBefore(eventEnd) && newEventEnd.isAfter(eventStart)) {
        return true;
      }
    }
    return false;
  }

  /// 報名活動 (替代 joinEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否已加入
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查時間衝突 (這需要在 Transaction 外部做嗎？為了效能可能需要，但為了正確性應該在內部，但 Firestore Transaction 限制讀取必須在寫入前且不能跨太多集合查詢複雜邏輯)
        // 由於 getUserEvents 比較複雜，我們在 Transaction 前先做一個 Check，或者在 Transaction 中只做簡單 Check
        // 為了避免 Transaction 失敗率高，我們將 Conflict Check 移到外部調用，或者在這裡做一個簡單的“同一天”檢查如果數據允許
        // 這裡暫時不做 Transaction 內的 Query，依賴調用前的檢查或樂觀鎖。
        // *但在這個方法內，我們必須確保邏輯完整。*
        // 我們假設 _hasTimeConflict 在外部調用或接受這一點風險。
        // 為了嚴謹，我們在此方法開頭調用（非 Transaction），雖然不是原子的，但足夠應對大多數情況。
      });

      // Transaction 外部檢查時間衝突
      final docSnapshot = await _eventsCollection.doc(eventId).get();
      if (!docSnapshot.exists) throw Exception('活動不存在');
      final eventData = DinnerEventModel.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);

      if (await _hasTimeConflict(userId, eventData.dateTime)) {
        throw Exception('與您現有的活動時間衝突');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final currentParticipantIds = List<String>.from(data['participantIds'] ?? []);
        final currentWaitingListIds = List<String>.from(data['waitingListIds'] ?? []);
        final currentParticipantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
        final maxParticipants = data['maxParticipants'] ?? DEFAULT_MAX_PARTICIPANTS;

        if (currentParticipantIds.contains(userId) || currentWaitingListIds.contains(userId)) {
           return; // 已經在裡面了，可能是併發導致，直接返回
        }

        if (currentParticipantIds.length < maxParticipants) {
          // 有空位，直接加入
          currentParticipantIds.add(userId);
          currentParticipantStatus[userId] = 'confirmed';

          final updates = {
            'participantIds': currentParticipantIds,
            'participantStatus': currentParticipantStatus,
          };

          if (currentParticipantIds.length == maxParticipants) {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
        } else {
          // 沒空位，加入候補
          currentWaitingListIds.add(userId);
          transaction.update(docRef, {'waitingListIds': currentWaitingListIds});
        }
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (替代 leaveEvent)
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        final now = DateTime.now();

        // 1. 檢查 24 小時限制
        if (eventDate.difference(now).inHours < 24) {
          throw Exception('活動開始前 24 小時內不可取消');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingListIds = List<String>.from(data['waitingListIds'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        bool isParticipant = participantIds.contains(userId);
        bool isWaiter = waitingListIds.contains(userId);

        if (!isParticipant && !isWaiter) {
          throw Exception('您未報名此活動');
        }

        final updates = <String, dynamic>{};

        if (isWaiter) {
          waitingListIds.remove(userId);
          updates['waitingListIds'] = waitingListIds;
        } else if (isParticipant) {
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 自動遞補邏輯
          if (waitingListIds.isNotEmpty) {
            final nextUserId = waitingListIds.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed';
            updates['waitingListIds'] = waitingListIds;
            // TODO: 發送通知給 nextUserId
          } else {
            // 如果沒人候補且活動原本是 confirmed，可能需要變回 pending?
             // 如果少於 maxParticipants (例如 6) 且原本是 confirmed
             // 但這裡我們保持 status 不變，除非需要重置
             if (data['status'] == 'confirmed' && participantIds.length < (data['maxParticipants'] ?? DEFAULT_MAX_PARTICIPANTS)) {
               updates['status'] = 'pending';
             }
          }

          if (participantIds.isEmpty) {
             updates['status'] = 'cancelled';
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  // 兼容舊方法
  Future<void> joinEvent(String eventId, String userId) async {
    return registerForEvent(eventId, userId);
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    return unregisterFromEvent(eventId, userId);
  }

  /// 獲取推薦的活動列表（用於配對）
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', isEqualTo: 'pending')
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              !event.isFull && // 使用 getter
              event.dateTime.isAfter(DateTime.now())
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
  }

  /// 監聽單個活動更新
  Stream<DinnerEventModel?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// 計算本週四和下週四的日期
  List<DateTime> getThursdayDates() {
    final now = DateTime.now();
    DateTime thisThursday;
    if (now.weekday <= DateTime.thursday) {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday));
    } else {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday + 7));
    }
    
    thisThursday = DateTime(
      thisThursday.year,
      thisThursday.month,
      thisThursday.day,
      19,
      0,
    );
    
    final nextThursday = thisThursday.add(const Duration(days: 7));
    return [thisThursday, nextThursday];
  }

  /// 加入或創建活動（智慧配對）
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _eventsCollection
          .where('city', isEqualTo: city)
          .where('status', isEqualTo: 'pending')
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? DEFAULT_MAX_PARTICIPANTS;
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (participantIds.length < maxParticipants) {
          targetEventId = doc.id;
          break;
        }
      }
      
      if (targetEventId != null) {
        await registerForEvent(targetEventId, userId);
        return targetEventId;
      }
      
      return await createEvent(
        creatorId: userId,
        dateTime: date,
        budgetRange: 1,
        city: city,
        district: district,
        notes: '週四固定晚餐聚會',
      );
      
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }
}
