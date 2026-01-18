import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數
  static const int MAX_PARTICIPANTS = 6;

  /// 創建新的晚餐活動
  /// 
  /// [creatorId] 創建者 ID
  /// [dateTime] 日期時間
  /// [budgetRange] 預算範圍
  /// [city] 城市
  /// [district] 地區
  /// [notes] 備註（可選）
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
  }) async {
    try {
      // 創建新的文檔引用以獲取 ID
      final docRef = _eventsCollection.doc();
      
      // 初始參與者為創建者
      final participantIds = [creatorId];
      final participantStatus = {creatorId: EventRegistrationStatus.registered.toStringValue()};
      
      // 預設破冰問題（之後可以從題庫隨機選取）
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
        maxParticipants: MAX_PARTICIPANTS,
        currentParticipants: 1,
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitlist: [],
        status: 'pending', // 等待配對
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
  /// 
  /// [eventId] 活動 ID
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
  /// 
  /// [userId] 用戶 ID
  /// [status] 活動狀態過濾（可選）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 這裡需要兩個查詢：一個查 participantIds，一個查 waitlist
      // Firestore 不支持 OR 查詢 arrayContains
      // 所以我們先查 participantIds

      Query queryParticipants = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        queryParticipants = queryParticipants.where('status', isEqualTo: status);
      }

      final snapshotParticipants = await queryParticipants.get();

      // 再查 waitlist
      Query queryWaitlist = _eventsCollection
          .where('waitlist', arrayContains: userId);

      if (status != null) {
        queryWaitlist = queryWaitlist.where('status', isEqualTo: status);
      }

      final snapshotWaitlist = await queryWaitlist.get();

      final eventsMap = <String, DinnerEventModel>{};

      for (var doc in snapshotParticipants.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in snapshotWaitlist.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      final events = eventsMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名參加活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 1. 獲取活動詳情
      final eventSnapshot = await _eventsCollection.doc(eventId).get();
      if (!eventSnapshot.exists) {
        throw Exception('活動不存在');
      }
      final eventData = eventSnapshot.data() as Map<String, dynamic>;
      final event = DinnerEventModel.fromMap(eventData, eventId);

      // 2. 檢查重複報名
      if (event.participantIds.contains(userId)) {
        throw Exception('您已報名此活動');
      }
      if (event.waitlist.contains(userId)) {
        throw Exception('您已在候補名單中');
      }

      // 3. 檢查時間衝突
      // 假設活動時間 +/- 3小時內不能有其他活動
      await _checkTimeConflict(userId, event.dateTime);

      // 4. 執行報名邏輯 (Transaction)
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() as Map<String, dynamic>;

        // 重新讀取數據以確保一致性
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
        // 再次檢查重複 (以防併發)
        if (participantIds.contains(userId) || waitlist.contains(userId)) {
          return; // 已經加入，不做任何事 (或者拋出異常)
        }

        if (participantIds.length < maxParticipants) {
          // 還有名額，直接加入
          participantIds.add(userId);
          participantStatus[userId] = EventRegistrationStatus.registered.toStringValue();

          final updates = {
            'participantIds': participantIds,
            'currentParticipants': participantIds.length,
            'participantStatus': participantStatus,
          };

          // 如果滿員，更新狀態
          if (participantIds.length >= maxParticipants) {
             // 滿員不代表 confirmed，confirmed 可能是系統確認
             // 這裡暫時不自動改成 confirmed，除非所有人都確認
             // 但根據舊邏輯：
             if (participantIds.length == maxParticipants) {
                updates['status'] = 'confirmed'; // 舊邏輯滿員即確認
                updates['confirmedAt'] = FieldValue.serverTimestamp();
             }
          }

          transaction.update(docRef, updates);
        } else {
          // 已滿員，加入候補
          waitlist.add(userId);
          participantStatus[userId] = EventRegistrationStatus.waitlist.toStringValue();

          transaction.update(docRef, {
            'waitlist': waitlist,
            'participantStatus': participantStatus,
          });
        }
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime newEventTime) async {
    final myEvents = await getUserEvents(userId, status: null); // 獲取所有狀態

    for (var event in myEvents) {
      if (event.status == 'cancelled' ||
          event.statusText == '已取消' ||
          event.participantStatus[userId] == EventRegistrationStatus.cancelled.toStringValue()) {
        continue;
      }

      final diff = event.dateTime.difference(newEventTime).inHours.abs();
      if (diff < 3) {
        throw Exception('此時段已與其他活動衝突 (${event.dateTime.toString().split('.')[0]})');
      }
    }
  }

  /// 取消報名
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final eventDateTime = (data['dateTime'] as Timestamp).toDate();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        bool isRegistered = participantIds.contains(userId);
        bool isWaitlisted = waitlist.contains(userId);
        
        if (!isRegistered && !isWaitlisted) {
          throw Exception('您未報名此活動');
        }

        // 檢查截止時間 (活動前24小時)
        // 只有已報名者受此限制，候補者可隨時退出
        if (isRegistered) {
          final now = DateTime.now();
          final deadline = eventDateTime.subtract(const Duration(hours: 24));
          if (now.isAfter(deadline)) {
            throw Exception('活動開始前 24 小時內不可取消');
          }
        }

        final updates = <String, dynamic>{};

        if (isWaitlisted) {
          // 只是候補，直接移除
          waitlist.remove(userId);
          participantStatus.remove(userId);
          updates['waitlist'] = waitlist;
          updates['participantStatus'] = participantStatus;
        } else {
          // 是正式參與者
          participantIds.remove(userId);
          participantStatus.remove(userId); // 或者標記為 cancelled ? 需求說 "爽約記錄"，這裡是主動取消。
          // 如果是主動取消，應該直接移除，不計入爽約。

          // 自動遞補邏輯
          if (waitlist.isNotEmpty) {
            final nextUserId = waitlist.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = EventRegistrationStatus.registered.toStringValue();

            // TODO: 發送通知給 nextUserId
            print('User $nextUserId promoted from waitlist');

            updates['waitlist'] = waitlist;
          }

          updates['participantIds'] = participantIds;
          updates['currentParticipants'] = participantIds.length;
          updates['participantStatus'] = participantStatus;

          // 如果沒人遞補，且原本是滿員(confirmed)，現在變成不滿員
          if (data['status'] == 'confirmed' && participantIds.length < (data['maxParticipants'] ?? MAX_PARTICIPANTS)) {
            updates['status'] = 'pending';
          }

          if (participantIds.isEmpty && waitlist.isEmpty) {
            updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  // Deprecated methods for compatibility

  /// Deprecated: use [registerForEvent]
  Future<void> joinEvent(String eventId, String userId) async {
    return registerForEvent(eventId, userId);
  }

  /// Deprecated: use [unregisterFromEvent]
  Future<void> leaveEvent(String eventId, String userId) async {
    return unregisterFromEvent(eventId, userId);
  }

  /// 獲取推薦的活動列表（用於配對）
  /// 
  /// [city] 城市
  /// [budgetRange] 預算範圍
  /// [excludeEventIds] 排除的活動 ID（如已參加的）
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
          .orderBy('dateTime') // 按時間排序
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              !event.isFull &&
              event.dateTime.isAfter(DateTime.now()) // 只顯示未來的活動
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
  }

  /// 監聽單個活動更新
  ///
  /// [eventId] 活動 ID
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
    thisThursday = DateTime(thisThursday.year, thisThursday.month, thisThursday.day, 19, 0);
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
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
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
