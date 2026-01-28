import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

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

      // Default deadline 24 hours before event
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
        waitingListIds: [],
        registrationDeadline: registrationDeadline,
        status: EventStatus.pending, // 等待配對
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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
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

  /// 獲取用戶活動歷史 (Completed or Cancelled)
  Future<List<DinnerEventModel>> getEventHistory(String userId) async {
    try {
      // Cannot filter by array-contains (participantIds) and in (status) together efficiently in some cases,
      // but Firestore allows array-contains and in.
      // Alternatively, just get all user events and filter in memory.

      // Get all events where user is participant or waitlisted
      // Firestore doesn't support logical OR for different fields directly in one simple query without multiple queries.
      // Let's query by participantIds first. Waitlist history might be less critical or handled separately.
      // If we want both, we might need two queries or rely on a "involvedUsers" field if we had one.
      // For now, let's just fetch where user is participant.

      final querySnapshot = await _eventsCollection
          .where('participantIds', arrayContains: userId)
          .where('status', whereIn: [EventStatus.completed.name, EventStatus.cancelled.name])
          .get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return events;
    } catch (e) {
      throw Exception('獲取活動歷史失敗: $e');
    }
  }

  /// 加入活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        // Check deadline
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        if (event.participantIds.length >= DinnerEventModel.maxParticipants) {
          // Join waiting list
          final waitingListIds = List<String>.from(event.waitingListIds);
          waitingListIds.add(userId);

          transaction.update(docRef, {
            'waitingListIds': waitingListIds,
          });
        } else {
          // Join participants
          final participantIds = List<String>.from(event.participantIds);
          participantIds.add(userId);

          final participantStatus = Map<String, dynamic>.from(event.participantStatus);
          participantStatus[userId] = 'confirmed';

          final updates = <String, dynamic>{
            'participantIds': participantIds,
            'participantStatus': participantStatus,
          };

          if (participantIds.length == DinnerEventModel.maxParticipants) {
            updates['status'] = EventStatus.confirmed.name;
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
        }
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 退出活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        if (event.waitingListIds.contains(userId)) {
          // Remove from waiting list
          final waitingListIds = List<String>.from(event.waitingListIds);
          waitingListIds.remove(userId);
          transaction.update(docRef, {'waitingListIds': waitingListIds});
          return;
        }
        
        if (!event.participantIds.contains(userId)) {
          throw Exception('您未加入此活動');
        }

        // Remove from participants
        final participantIds = List<String>.from(event.participantIds);
        participantIds.remove(userId);
        
        final participantStatus = Map<String, dynamic>.from(event.participantStatus);
        participantStatus.remove(userId);

        final waitingListIds = List<String>.from(event.waitingListIds);

        // Promote from waiting list if available
        if (waitingListIds.isNotEmpty) {
          final nextUserId = waitingListIds.removeAt(0);
          participantIds.add(nextUserId);
          participantStatus[nextUserId] = 'confirmed'; // Auto-confirm promoted user? Or pending?
          // For simplicity, auto-confirm for now.
        }

        final updates = <String, dynamic>{
          'participantIds': participantIds,
          'participantStatus': participantStatus,
          'waitingListIds': waitingListIds,
        };

        // Update status logic
        if (participantIds.isEmpty) {
          updates['status'] = EventStatus.cancelled.name;
        } else if (participantIds.length < DinnerEventModel.maxParticipants && event.status == EventStatus.confirmed) {
           // If it was confirmed (full) but now not full and no waitlist replacement
           // Set back to pending so others can join
           updates['status'] = EventStatus.pending.name;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
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
          .where('status', isEqualTo: EventStatus.pending.name)
          .orderBy('dateTime') // 按時間排序
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.participantIds.length < DinnerEventModel.maxParticipants &&
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
    
    // 計算本週四
    DateTime thisThursday;
    if (now.weekday <= DateTime.thursday) {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday));
    } else {
      // 已經過了週四，本週四算下週的
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
          .where('status', isEqualTo: EventStatus.pending.name)
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
        
        // 如果用戶已經在某個活動中，直接返回該活動 ID
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到一個未滿的活動 (人數 < MAX_PARTICIPANTS)
        // 目前邏輯：循序填滿。找到第一個有空位的桌子就加入。
        if (participantIds.length < DinnerEventModel.maxParticipants) {
          targetEventId = doc.id;
          break; // 找到一個就夠了
        }
      }
      
      // 2. 如果找到活動，加入它
      if (targetEventId != null) {
        await joinEvent(targetEventId, userId);
        return targetEventId;
      }
      
      // 3. 如果沒找到（或都滿了），創建新活動（開新桌）
      return await createEvent(
        creatorId: userId,
        dateTime: date, // 使用傳入的準確時間 (19:00)
        budgetRange: 1, // 預設 500-800
        city: city,
        district: district,
        notes: '週四固定晚餐聚會',
      );
      
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }
}
