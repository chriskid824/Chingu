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
        maxParticipants: MAX_PARTICIPANTS,
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
      // 查詢用戶在 participantIds 或 waitingListIds 中的活動
      // Firestore 不支持同時查詢兩個數組字段的 contains，所以分開查或查一個
      // 這裡我們先查 participantIds，這涵蓋大部分情況
      // TODO: 考慮如何高效查詢 waitlist

      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 獲取 waitlist 的活動
      final waitlistQuery = await _eventsCollection
          .where('waitingListIds', arrayContains: userId)
          .get();

      final waitlistEvents = waitlistQuery.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 合併並去重
      final allEventIds = events.map((e) => e.id).toSet();
      for (var e in waitlistEvents) {
        if (!allEventIds.contains(e.id)) {
          events.add(e);
        }
      }

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
  /// 返回: EventRegistrationStatus (registered 或 waitlist)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 重複報名檢查
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在等候清單中');
        }

        // 2. 時間衝突檢查 (需要查詢此用戶的其他活動)
        // 為了性能，我們這裡先只做簡單檢查，或者在 Cloud Function 中做更嚴格檢查
        // 這裡我們先假設如果不衝突才調用此函數，或者在此處進行異步查詢(注意 transaction 限制)
        // 由於 transaction 必須是讀-寫操作，不能在中間插入其他查詢，
        // 所以嚴格的時間衝突檢查最好在 transaction 之外做，或者優化數據結構。
        // 這裡我們暫時跳過嚴格的 transaction 內時間檢查，依靠前端或外部檢查。
        
        // 3. 滿員檢查與邏輯
        EventRegistrationStatus resultStatus;

        if (event.participantIds.length < event.maxParticipants) {
          // 還有名額 -> 加入參與者
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newStatus = Map<String, String>.from(event.participantStatus);
          newStatus[userId] = 'confirmed';

          transaction.update(docRef, {
            'participantIds': newParticipantIds,
            'participantStatus': newStatus,
            // 如果滿員，更新狀態
            if (newParticipantIds.length == event.maxParticipants && event.status == 'pending')
              'status': 'confirmed',
            if (newParticipantIds.length == event.maxParticipants && event.status == 'pending')
              'confirmedAt': FieldValue.serverTimestamp(),
          });
          resultStatus = EventRegistrationStatus.registered;
        } else {
          // 已滿 -> 加入等候清單
          final newWaitingListIds = List<String>.from(event.waitingListIds)..add(userId);
          transaction.update(docRef, {
            'waitingListIds': newWaitingListIds,
          });
          resultStatus = EventRegistrationStatus.waitlist;
        }

        return resultStatus;
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 檢查時間衝突 (Helper method to be called before register)
  Future<void> checkTimeConflict(String userId, DateTime eventTime) async {
    // 查詢用戶所有未取消的活動
    final userEvents = await getUserEvents(userId);
    final upcomingEvents = userEvents.where((e) =>
      e.status != 'cancelled' &&
      e.status != 'completed' &&
      e.dateTime.isAfter(DateTime.now())
    );

    for (var existingEvent in upcomingEvents) {
      final diff = existingEvent.dateTime.difference(eventTime).inHours.abs();
      if (diff < 2) { // 假設活動時長 2 小時
        throw Exception('與現有活動時間衝突 (${existingEvent.dateTime.toString().split('.')[0]})');
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否在名單中
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlist = event.waitingListIds.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未報名此活動');
        }

        // 2. 取消截止時間檢查 (24小時)
        // 只有正式參與者受此限制，waitlist 隨時可退
        if (isParticipant) {
          final now = DateTime.now();
          final deadline = event.dateTime.subtract(const Duration(hours: 24));
          if (now.isAfter(deadline)) {
            throw Exception('活動前 24 小時內不可取消');
          }
        }

        // 3. 處理退出邏輯
        if (isWaitlist) {
          // 從 waitlist 移除
          final newWaitingList = List<String>.from(event.waitingListIds)..remove(userId);
          transaction.update(docRef, {'waitingListIds': newWaitingList});
        } else {
          // 從參與者移除
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newStatus = Map<String, String>.from(event.participantStatus)..remove(userId);
          final newWaitingList = List<String>.from(event.waitingListIds);

          // 自動遞補邏輯
          if (newWaitingList.isNotEmpty) {
            final nextUserId = newWaitingList.removeAt(0); // 取出第一位
            newParticipantIds.add(nextUserId);
            newStatus[nextUserId] = 'confirmed'; // 自動確認遞補者

            // TODO: 發送通知給 nextUserId "您已成功遞補!"
          }

          final updates = <String, dynamic>{
            'participantIds': newParticipantIds,
            'participantStatus': newStatus,
            'waitingListIds': newWaitingList,
          };

          // 狀態更新 logic
          // 如果原本是 confirmed 且現在人數不足 6 人 (且沒有遞補)，變回 pending
          if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
            updates['status'] = 'pending';
          }

          // 如果全部人都退出了
          if (newParticipantIds.isEmpty) {
            updates['status'] = 'cancelled';
          }

          transaction.update(docRef, updates);
        }
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
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
              event.participantIds.length < event.maxParticipants &&
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
  /// 用於一鍵報名功能
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      // 先檢查時間衝突
      await checkTimeConflict(userId, date);

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
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到未滿的桌子
        final max = data['maxParticipants'] ?? 6;
        if (participantIds.length < max) {
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
