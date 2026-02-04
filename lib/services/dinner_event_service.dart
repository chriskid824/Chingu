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
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 註冊活動 (替代 joinEvent)
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  /// 返回註冊狀態 (Registered or Waitlist)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        // 1. 重複報名檢查
        if (event.participantIds.contains(userId)) {
           throw Exception('您已報名此活動');
        }
        if (event.waitlist.contains(userId)) {
           throw Exception('您已在候補名單中');
        }

        // 2. 時間衝突檢查
        await _checkTimeConflict(userId, event.dateTime);

        // 3. 滿員檢查與候補邏輯
        EventRegistrationStatus status;
        List<String> newParticipantIds = List.from(event.participantIds);
        List<String> newWaitlist = List.from(event.waitlist);
        Map<String, String> newParticipantStatus = Map.from(event.participantStatus);

        if (newParticipantIds.length < event.maxParticipants) {
          newParticipantIds.add(userId);
          newParticipantStatus[userId] = 'confirmed';
          status = EventRegistrationStatus.registered;
        } else {
          newWaitlist.add(userId);
          status = EventRegistrationStatus.waitlist;
        }

        final updates = {
          'participantIds': newParticipantIds,
          'waitlist': newWaitlist,
          'participantStatus': newParticipantStatus,
        };

        // 如果人數達到 maxParticipants 人，自動確認活動
        if (newParticipantIds.length == event.maxParticipants && event.status == 'pending') {
          updates['status'] = 'confirmed';
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
        return status;
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime eventTime) async {
    // 假設活動持續 3 小時
    final eventEnd = eventTime.add(const Duration(hours: 3));
    final eventStart = eventTime.subtract(const Duration(hours: 3)); // 檢查前後3小時

    // 查詢用戶的所有活動 (這裡為了效率，簡單查當天，然後在內存過濾)
    // 更好的做法是在 User model 存活動時間索引，或者用 Cloud Function 維護
    // 這裡我們只查未來的活動
    final existingEvents = await getUserEvents(userId);

    for (var existingEvent in existingEvents) {
      // 忽略已取消的活動
      if (existingEvent.status == 'cancelled') continue;

      final existingTime = existingEvent.dateTime;

      // 檢查是否同一天且時間重疊 (< 3小時差距)
      if (existingTime.year == eventTime.year &&
          existingTime.month == eventTime.month &&
          existingTime.day == eventTime.day) {

        final difference = existingTime.difference(eventTime).inHours.abs();
        if (difference < 3) {
           throw Exception('此時段您已有其他活動 (${existingEvent.dateTime.toString().substring(0, 16)})');
        }
      }
    }
  }

  /// 取消報名 (替代 leaveEvent)
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
        final event = DinnerEventModel.fromMap(data, eventId);

        // 1. 取消截止時間檢查 (活動前24小時)
        final now = DateTime.now();
        final hoursUntilEvent = event.dateTime.difference(now).inHours;
        
        if (hoursUntilEvent < 24 && event.participantIds.contains(userId)) {
           // 如果是在 waitlist 裡，隨時可以取消，但如果是 participant，受 24h 限制
           throw Exception('活動開始前 24 小時內不可取消');
        }

        List<String> newParticipantIds = List.from(event.participantIds);
        List<String> newWaitlist = List.from(event.waitlist);
        Map<String, String> newParticipantStatus = Map.from(event.participantStatus);
        
        if (newParticipantIds.contains(userId)) {
          // 用戶是正式參與者
          newParticipantIds.remove(userId);
          newParticipantStatus.remove(userId);

          // 自動遞補邏輯
          if (newWaitlist.isNotEmpty) {
            final nextUserId = newWaitlist.removeAt(0);
            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed';

            // TODO: 發送通知給 nextUserId (恭喜遞補成功)
          }
        } else if (newWaitlist.contains(userId)) {
          // 用戶在候補名單
          newWaitlist.remove(userId);
        } else {
          throw Exception('您未報名此活動');
        }

        final updates = {
          'participantIds': newParticipantIds,
          'waitlist': newWaitlist,
          'participantStatus': newParticipantStatus,
        };

        // 如果活動人數少於 maxParticipants 人且狀態為已確認，變回 pending (除非有遞補，通常遞補後還是滿的)
        if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
          updates['status'] = 'pending';
        }

        // 如果沒有參與者了
        if (newParticipantIds.isEmpty) {
          updates['status'] = 'cancelled';
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消失敗: $e');
    }
  }

  /// 兼容舊方法：加入活動 -> registerForEvent
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// 兼容舊方法：退出活動 -> unregisterFromEvent
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
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
              event.participantIds.length < event.maxParticipants &&
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
    
    // 設定時間為晚上 7 點 (19:00)
    thisThursday = DateTime(
      thisThursday.year,
      thisThursday.month,
      thisThursday.day,
      19,
      0,
    );
    
    // 下週四 = 本週四 + 7天
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
