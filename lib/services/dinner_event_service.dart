import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

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
      final participantStatus = {creatorId: 'confirmed'};
      
      // 預設破冰問題（之後可以從題庫隨機選取）
      final icebreakerQuestions = [
        '如果可以和世界上任何人共進晚餐，你會選誰？',
        '最近一次讓你開懷大笑的事情是什麼？',
        '你最喜歡的旅行經歷是什麼？',
      ];

      // 設置報名截止時間為活動前 24 小時
      final registrationDeadline = dateTime.subtract(const Duration(hours: 24));

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
        status: 'pending', // 等待配對
        createdAt: DateTime.now(),
        icebreakerQuestions: icebreakerQuestions,
        registrationDeadline: registrationDeadline,
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
      // 查詢用戶參與的活動 (participantIds 或 waitingListIds)
      // Firestore 不支援 OR 查詢跨欄位，所以分開查或查完過濾
      // 這裡先查 participantIds

      Query participantQuery = _eventsCollection.where('participantIds', arrayContains: userId);
      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status);
      }
      final participantSnapshot = await participantQuery.get();

      // 查 waitingListIds
      Query waitlistQuery = _eventsCollection.where('waitingListIds', arrayContains: userId);
      if (status != null) {
        waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
      }
      final waitlistSnapshot = await waitlistQuery.get();

      // 合併結果並去重
      final Map<String, DinnerEventModel> eventsMap = {};

      for (var doc in participantSnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      for (var doc in waitlistSnapshot.docs) {
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

  /// 報名活動 (registerForEvent)
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final eventModel = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否已報名或在候補名單
        if (eventModel.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (eventModel.waitingListIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查報名截止時間
        if (eventModel.registrationDeadline != null && DateTime.now().isAfter(eventModel.registrationDeadline!)) {
           throw Exception('報名已截止');
        }

        // 3. 檢查時間衝突 (在 Transaction 外做比較好，但為了數據一致性，這裡假設先檢查過或接受此處不包含其他活動的鎖)
        // 由於無法在 Transaction 中讀取大量文檔而不鎖定它們，我們這裡假設用戶不會同時報名多個衝突活動
        // 實際應用中可能需要在外部先檢查
        
        // 4. 判斷加入正式名單還是候補名單
        bool addToWaitlist = false;
        if (eventModel.currentParticipants >= eventModel.maxParticipants) {
          addToWaitlist = true;
        }

        // 準備更新數據
        final updates = <String, dynamic>{};

        if (addToWaitlist) {
          final newWaitlist = List<String>.from(eventModel.waitingListIds)..add(userId);
          updates['waitingListIds'] = newWaitlist;
        } else {
          final newParticipants = List<String>.from(eventModel.participantIds)..add(userId);
          final newStatusMap = Map<String, String>.from(eventModel.participantStatus);
          newStatusMap[userId] = 'confirmed'; // 預設確認

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatusMap;
          updates['currentParticipants'] = eventModel.currentParticipants + 1;

          // 如果滿員，更新狀態 (視需求而定，若原本是 pending，滿員後可變 confirmed)
          if (newParticipants.length >= eventModel.maxParticipants) {
             updates['status'] = 'confirmed';
             if (eventModel.confirmedAt == null) {
               updates['confirmedAt'] = FieldValue.serverTimestamp();
             }
          }
        }

        transaction.update(docRef, updates);
      });

      // 5. 檢查時間衝突 (作為後置檢查，若失敗則提示用戶但不回滾，或者在前端先檢查)
      // 這裡省略，建議在前端調用 checkTimeConflict

    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<bool> checkTimeConflict(String userId, DateTime newEventTime) async {
    // 獲取用戶所有未完成的活動 (pending, confirmed)
    final events = await getUserEvents(userId);
    final activeEvents = events.where((e) =>
      (e.status == 'pending' || e.status == 'confirmed') &&
      e.dateTime.isAfter(DateTime.now())
    );

    for (var event in activeEvents) {
      // 假設活動持續 2 小時
      final existingStart = event.dateTime;
      final existingEnd = existingStart.add(const Duration(hours: 2));

      final newStart = newEventTime;
      final newEnd = newStart.add(const Duration(hours: 2));

      // 檢查重疊
      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  /// 退出活動 (unregisterFromEvent)
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

        final eventModel = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        bool isParticipant = eventModel.participantIds.contains(userId);
        bool isWaitlisted = eventModel.waitingListIds.contains(userId);

        if (!isParticipant && !isWaitlisted) {
          throw Exception('您未報名此活動');
        }

        // 檢查取消截止時間 (活動前24小時)
        // 只有正式參加者受此限制，候補者可隨時取消
        if (isParticipant) {
           final deadline = eventModel.dateTime.subtract(const Duration(hours: 24));
           if (DateTime.now().isAfter(deadline)) {
             throw Exception('活動前24小時內不可取消');
           }
        }

        final updates = <String, dynamic>{};

        if (isWaitlisted) {
          final newWaitlist = List<String>.from(eventModel.waitingListIds)..remove(userId);
          updates['waitingListIds'] = newWaitlist;
        } else {
          // 是正式參加者
          final newParticipants = List<String>.from(eventModel.participantIds)..remove(userId);
          final newStatusMap = Map<String, String>.from(eventModel.participantStatus);
          newStatusMap.remove(userId);

          // 處理候補遞補
          int currentCount = newParticipants.length;
          final newWaitlist = List<String>.from(eventModel.waitingListIds);

          if (newWaitlist.isNotEmpty) {
             final promotedUserId = newWaitlist.removeAt(0); // 取出第一位
             newParticipants.add(promotedUserId);
             newStatusMap[promotedUserId] = 'confirmed'; // 自動確認
             currentCount++;

             // TODO: 觸發通知給 promotedUserId
          }

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatusMap;
          updates['waitingListIds'] = newWaitlist;
          updates['currentParticipants'] = currentCount;

          // 如果人數少於最大值，可能需要更新狀態
          if (currentCount < eventModel.maxParticipants && eventModel.status == 'confirmed') {
             updates['status'] = 'pending'; // 變回 pending 等待配對
          }

           // 如果完全沒人了 (且無候補)，則取消活動
          if (currentCount == 0 && newWaitlist.isEmpty) {
             updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
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
              event.participantIds.length < 6 &&
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
  /// 
  /// [userId] 用戶 ID
  /// [date] 日期
  /// [city] 城市
  /// [district] 地區
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      // 1. 搜尋現有符合條件的活動
      // 條件：同日期、同地點、狀態為 pending、人數未滿 6 人
      // 由於 Firestore 查詢限制，我們先查城市和狀態，然後在內存中過濾
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _eventsCollection
          .where('city', isEqualTo: city)
          .where('status', isEqualTo: 'pending')
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // 1. 檢查地區
        if (data['district'] != district) continue;
        
        // 2. 檢查日期時間
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (participantIds.length < MAX_PARTICIPANTS) {
          targetEventId = doc.id;
          break;
        }
      }
      
      // 2. 如果找到活動，加入它
      if (targetEventId != null) {
        await registerForEvent(targetEventId, userId); // 使用新的 registerForEvent
        return targetEventId;
      }
      
      // 3. 如果沒找到（或都滿了），創建新活動（開新桌）
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

  /// Join Event (Backward Compatibility)
  /// Deprecated: Use registerForEvent instead
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// Leave Event (Backward Compatibility)
  /// Deprecated: Use unregisterFromEvent instead
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
  }
}
