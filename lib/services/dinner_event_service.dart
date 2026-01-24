import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數
  static const int MAX_PARTICIPANTS = 6;

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
      final participantStatus = {creatorId: EventRegistrationStatus.registered.name};
      
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
        currentParticipants: 1,
        maxParticipants: MAX_PARTICIPANTS,
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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventRegistrationStatus? status}) async {
    try {
      // 由於現在有 waitlist, participantIds 可能不包含 waitlist 用戶 (視 DinnerEventModel 實現而定)
      // 但我們的模型定義 waitlistIds 分開，所以這裡查詢比較複雜
      // 我們主要查詢 participantIds 或 waitlistIds

      // 策略：分別查詢或查詢所有相關
      // 這裡先查 participantIds
      Query queryRegistered = _eventsCollection
          .where('participantIds', arrayContains: userId);

      final snapshotRegistered = await queryRegistered.get();

      // 查 waitlist (如果需要)
      Query queryWaitlist = _eventsCollection
          .where('waitlistIds', arrayContains: userId);

      final snapshotWaitlist = await queryWaitlist.get();

      // 合併並去重
      final Map<String, DinnerEventModel> eventsMap = {};

      for (var doc in snapshotRegistered.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      for (var doc in snapshotWaitlist.docs) {
         eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      var events = eventsMap.values.toList();

      // 過濾狀態
      if (status != null) {
        events = events.where((e) {
           final userStatus = e.participantStatus[userId];
           return userStatus == status.name;
        }).toList();
      }

      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名活動 (Register)
  /// 
  /// 包含滿員檢查、時間衝突檢查、候補邏輯
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 0. 獲取活動時間以進行衝突檢查 (Soft check)
      final eventSnapshot = await _eventsCollection.doc(eventId).get();
      if (!eventSnapshot.exists) throw Exception('活動不存在');
      final eventData = DinnerEventModel.fromMap(eventSnapshot.data() as Map<String, dynamic>, eventId);

      if (await checkTimeConflict(userId, eventData.dateTime)) {
        throw Exception('您在該時段已有其他活動');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否已報名或在候補
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitlistIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 時間衝突檢查 (需要查詢用戶其他活動)
        // 注意：Transaction 中不能執行額外的 Query，除非該 Query 也包含在 Transaction 中 (Firestore 限制)
        // 但這裡我們需要查詢跨文檔。
        // 為避免 Transaction 失敗，建議在 Transaction 外做 "軟檢查"，或接受 Transaction 內無法嚴格保證跨文檔一致性 (除非鎖定所有文檔)。
        // 這裡我們選擇在 Transaction 外檢查 (簡單做法)，或者如果不嚴格要求原子性。
        // 正確做法：讀取用戶文檔中的 "upcomingEvents" 列表（如果有的話）。
        // 由於我們沒有維護這樣的列表，我們先跳過強一致性的時間檢查，改為邏輯檢查。
        // TODO: 實現嚴格的時間衝突檢查
        
        // 3. 滿員檢查與邏輯
        List<String> newParticipantIds = List.from(event.participantIds);
        List<String> newWaitlistIds = List.from(event.waitlistIds);
        Map<String, String> newStatus = Map.from(event.participantStatus);
        int newCurrentParticipants = event.currentParticipants;
        String? newEventStatus = event.status;

        if (event.currentParticipants >= event.maxParticipants) {
          // 滿員 -> 加入 Waitlist
          newWaitlistIds.add(userId);
          newStatus[userId] = EventRegistrationStatus.waitlist.name;
        } else {
          // 未滿 -> 加入 Participants
          newParticipantIds.add(userId);
          newStatus[userId] = EventRegistrationStatus.registered.name;
          newCurrentParticipants++;

          // 如果滿員了，且狀態是 pending，可以考慮轉為 confirmed
          if (newCurrentParticipants >= event.maxParticipants && event.status == 'pending') {
            newEventStatus = 'confirmed';
          }
        }

        transaction.update(docRef, {
          'participantIds': newParticipantIds,
          'waitlistIds': newWaitlistIds,
          'participantStatus': newStatus,
          'currentParticipants': newCurrentParticipants,
          'status': newEventStatus,
        });
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (Unregister)
  /// 
  /// 包含 24h 限制、候補遞補邏輯
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否在名單中
        bool isRegistered = event.participantIds.contains(userId);
        bool isWaitlisted = event.waitlistIds.contains(userId);
        
        if (!isRegistered && !isWaitlisted) {
           // 已經不在名單中，視為成功
           return;
        }

        // 2. 檢查時間限制 (24小時前)
        // 只有已報名者受此限制，候補者隨時可退出
        if (isRegistered) {
          final timeDifference = event.dateTime.difference(DateTime.now());
          if (timeDifference.inHours < 24) {
             throw Exception('活動開始前 24 小時內不可取消');
          }
        }

        List<String> newParticipantIds = List.from(event.participantIds);
        List<String> newWaitlistIds = List.from(event.waitlistIds);
        Map<String, String> newStatus = Map.from(event.participantStatus);
        int newCurrentParticipants = event.currentParticipants;

        // 3. 移除用戶
        if (isRegistered) {
          newParticipantIds.remove(userId);
          newStatus[userId] = EventRegistrationStatus.cancelled.name;
          newCurrentParticipants--;
        } else {
          newWaitlistIds.remove(userId);
          newStatus.remove(userId); // 候補取消直接移除狀態或是標記 cancelled? 這裡選擇移除或是標記
          // 如果想留紀錄，可以設為 cancelled，但不要留在 waitlistIds
          newStatus[userId] = EventRegistrationStatus.cancelled.name;
        }

        // 4. 候補遞補邏輯 (Auto-fill)
        // 如果有空位 (current < max) 且候補有人
        if (newCurrentParticipants < event.maxParticipants && newWaitlistIds.isNotEmpty) {
           final nextUserId = newWaitlistIds.removeAt(0); // 取出第一位
           newParticipantIds.add(nextUserId);
           newStatus[nextUserId] = EventRegistrationStatus.registered.name;
           newCurrentParticipants++;

           // TODO: 觸發通知給 nextUserId (恭喜候補成功)
        }

        // 狀態檢查
        String? newEventStatus = event.status;
        if (newCurrentParticipants == 0 && event.status != 'completed') {
           newEventStatus = 'cancelled'; // 沒人了
        } else if (newCurrentParticipants < event.maxParticipants && event.status == 'confirmed') {
           // 這裡策略：一旦 confirmed 就不輕易變回 pending，除非人數過少?
           // 暫時保持 confirmed
        }

        transaction.update(docRef, {
          'participantIds': newParticipantIds,
          'waitlistIds': newWaitlistIds,
          'participantStatus': newStatus,
          'currentParticipants': newCurrentParticipants,
          'status': newEventStatus,
        });
      });
    } catch (e) {
      throw Exception('取消失敗: $e');
    }
  }

  /// 檢查時間衝突 (Helper)
  Future<bool> checkTimeConflict(String userId, DateTime dateTime) async {
    // 簡單實作：檢查該用戶在該時間前後 2 小時是否有其他 confirmed/registered 活動
    final start = dateTime.subtract(const Duration(hours: 2));
    final end = dateTime.add(const Duration(hours: 2));

    // 查詢該用戶所有未來的活動
    final events = await getUserEvents(userId, status: EventRegistrationStatus.registered);

    for (var e in events) {
       if (e.dateTime.isAfter(start) && e.dateTime.isBefore(end)) {
         return true;
       }
    }
    return false;
  }

  /// 加入活動 (Legacy alias to registerForEvent)
  Future<void> joinEvent(String eventId, String userId) async {
     await registerForEvent(eventId, userId);
  }

  /// 退出活動 (Legacy alias to unregisterFromEvent)
  Future<void> leaveEvent(String eventId, String userId) async {
     await unregisterFromEvent(eventId, userId);
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
              !event.isFull && // 使用新的 isFull 檢查
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

  /// 加入或創建活動（智慧配對）
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      // 檢查時間衝突
      if (await checkTimeConflict(userId, date)) {
        throw Exception('您在該時段已有其他活動');
      }

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
        
        final event = DinnerEventModel.fromMap(data, doc.id);
        
        if (event.participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 尋找未滿的活動
        if (event.currentParticipants < event.maxParticipants) {
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
