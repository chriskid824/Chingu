import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = 6,
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
        maxParticipants: maxParticipants,
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
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('獲取活動詳情失敗: $e');
    }
  }

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 需要同時查詢 participantIds 和 waitlist
      // Firestore 不支持同時 array-contains 兩個欄位，所以分開查或查詢所有相關文檔
      // 這裡我們先查 participantIds，這通常是主要的
      // 如果要包含 waitlist，可能需要兩次查詢並合併，或者依賴客戶端過濾
      // 為了簡單起見，我們先只查 participantIds，這是舊邏輯

      // 改進：分別查詢參與的和候補的
      final registeredQuery = _eventsCollection.where('participantIds', arrayContains: userId);
      final waitlistQuery = _eventsCollection.where('waitlist', arrayContains: userId);

      final results = await Future.wait([registeredQuery.get(), waitlistQuery.get()]);

      final Map<String, DinnerEventModel> eventsMap = {};

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          if (!eventsMap.containsKey(doc.id)) {
            eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
        }
      }

      var events = eventsMap.values.toList();

      if (status != null) {
        events = events.where((e) => e.status == status).toList();
      }
      
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名參加活動（包含候補邏輯）
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 0. 檢查時間衝突
      // 為了避免在 Transaction 內進行複雜查詢，先獲取活動資訊並檢查
      final targetEvent = await getEvent(eventId);
      if (targetEvent == null) throw Exception('活動不存在');

      if (await hasTimeConflict(userId, targetEvent.dateTime)) {
        throw Exception('此時段已與您報名的其他活動衝突');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否已報名或在候補名單
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitlist.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查時間衝突 (需要查詢用戶的其他活動)
        // 注意：在 Transaction 中進行外部查詢可能會影響性能，但為了數據完整性是必要的
        // 為了避免 Firestore Transaction 限制（讀取必須在寫入前），我們先進行查詢
        // 但這裡我們無法在 transaction 內部做 query (除非是 get)，
        // 且 getUserEvents 不是 transactional 的。
        // 這是一個權衡。我們在 transaction 前檢查大致衝突，或者假設衝突檢查允許輕微 race condition。
        // 正確做法：應用層檢查衝突，Transaction 檢查名額。
        
        // 這裡暫時跳過 Transaction 內的衝突檢查，因為需要查詢大量數據。
        // 我們假設前端或上一層已做過基本檢查，這裡只做最後的數據寫入。
        // (若要嚴格檢查，需在 transaction 外查好，傳入 transaction，但這很複雜)

        // 3. 檢查名額並更新
        final updates = <String, dynamic>{};

        if (event.participantIds.length < event.maxParticipants) {
          // 還有名額，直接加入
          final newParticipants = List<String>.from(event.participantIds)..add(userId);
          final newStatus = Map<String, String>.from(event.participantStatus);
          newStatus[userId] = 'confirmed'; // 自動確認

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatus;

          // 如果滿了，標記活動確認（如果是 pending）
          if (newParticipants.length >= event.maxParticipants && event.status == 'pending') {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 滿了，加入候補
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          updates['waitlist'] = newWaitlist;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名（包含候補遞補邏輯）
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否相關
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlisted = event.waitlist.contains(userId);

        if (!isParticipant && !isWaitlisted) {
          throw Exception('您未報名此活動');
        }

        // 2. 檢查取消時間限制 (僅針對正式參與者)
        if (isParticipant) {
          final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
          if (hoursUntilEvent < 24) {
            throw Exception('活動前 24 小時內不可取消');
          }
        }

        final updates = <String, dynamic>{};

        if (isWaitlisted) {
          // 只是候補，直接移除
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        } else {
          // 是正式參與者
          final newParticipants = List<String>.from(event.participantIds)..remove(userId);
          final newStatus = Map<String, String>.from(event.participantStatus)..remove(userId);
          final newWaitlist = List<String>.from(event.waitlist);

          // 3. 處理遞補
          if (newWaitlist.isNotEmpty) {
            // 取出第一位候補
            final promotedUserId = newWaitlist.removeAt(0);
            newParticipants.add(promotedUserId);
            newStatus[promotedUserId] = 'confirmed'; // 遞補者自動確認

            // TODO: 觸發通知給 promotedUserId
          }

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatus;
          updates['waitlist'] = newWaitlist;

          // 狀態檢查
          // 如果人數變少且沒有候補，可能需要從 confirmed 變回 pending？
          // 需求說：滿員後自動加入 waitlist, 有人取消自動遞補。
          // 這裡如果不滿員了，是否要變回 pending？
          // 暫時保持 confirmed 狀態，或者根據人數判斷。
          // 為了安全，如果少於 maxParticipants 且 waitlist 空了，可以考慮變回 pending，
          // 但既然已經 confirmed，可能餐廳已訂，還是保持 confirmed 比較好，除非人數過少。
          // 這裡保持原邏輯：如果只剩0人，cancel。否則保持原樣。
           if (newParticipants.isEmpty) {
            updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 檢查時間衝突
  /// 此方法應在調用 registerForEvent 前在 UI 層或 Service 層調用
  Future<bool> hasTimeConflict(String userId, DateTime newEventTime) async {
    final userEvents = await getUserEvents(userId);
    // 假設活動持續 3 小時
    const eventDuration = Duration(hours: 3);
    final newEventEnd = newEventTime.add(eventDuration);

    for (var event in userEvents) {
      // 忽略已取消的活動
      if (event.status == 'cancelled') continue;

      final eventStart = event.dateTime;
      final eventEnd = eventStart.add(eventDuration);

      // 檢查時間重疊
      if (newEventTime.isBefore(eventEnd) && newEventEnd.isAfter(eventStart)) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // 保留舊方法以兼容，或重定向到新邏輯
  // ---------------------------------------------------------------------------

  /// 加入活動 (舊 API，重定向到 registerForEvent)
  Future<void> joinEvent(String eventId, String userId) async {
    return registerForEvent(eventId, userId);
  }

  /// 退出活動 (舊 API，重定向到 unregisterFromEvent)
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
      // 查詢同城市、同預算、狀態為 pending 的活動
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
              !event.isFull &&
              event.dateTime.isAfter(DateTime.now())
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
  }

  Stream<DinnerEventModel?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

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
        
        // 使用 Model 檢查人數
        final event = DinnerEventModel.fromMap(data, doc.id);

        if (event.participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (!event.isFull) {
          targetEventId = doc.id;
          break;
        }
      }
      
      if (targetEventId != null) {
        await joinEvent(targetEventId, userId);
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
