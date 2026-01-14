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
  /// [registrationDeadline] 報名截止時間
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    DateTime? registrationDeadline,
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
        status: EventStatus.pending, // 等待配對
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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 查找用戶在參與者或候補名單中的活動
      Query query1 = _eventsCollection.where('participantIds', arrayContains: userId);
      Query query2 = _eventsCollection.where('waitlistIds', arrayContains: userId);

      if (status != null) {
        query1 = query1.where('status', isEqualTo: status.name);
        query2 = query2.where('status', isEqualTo: status.name);
      }

      final results = await Future.wait([query1.get(), query2.get()]);

      final Map<String, DinnerEventModel> eventsMap = {};

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          if (!eventsMap.containsKey(doc.id)) {
             eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
        }
      }

      final events = eventsMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動 (或候補)
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

        // 檢查報名截止時間
        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitlistIds.contains(userId)) {
           throw Exception('您已在候補名單中');
        }

        final updates = <String, dynamic>{};

        if (event.participantIds.length >= MAX_PARTICIPANTS) {
          // 活動已滿，加入候補
          final waitlistIds = List<String>.from(event.waitlistIds)..add(userId);
          updates['waitlistIds'] = waitlistIds;
        } else {
          // 加入活動
          final participantIds = List<String>.from(event.participantIds)..add(userId);
          final participantStatus = Map<String, dynamic>.from(event.participantStatus);
          participantStatus[userId] = 'confirmed'; // 默認確認

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 如果人數達到 MAX_PARTICIPANTS，自動確認活動 (如果還在 pending)
          if (participantIds.length == MAX_PARTICIPANTS && event.status == EventStatus.pending) {
            updates['status'] = EventStatus.confirmed.name;
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 退出活動 (或候補)
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
        
        final updates = <String, dynamic>{};
        bool changed = false;

        if (event.waitlistIds.contains(userId)) {
          // 從候補移除
          final waitlistIds = List<String>.from(event.waitlistIds)..remove(userId);
          updates['waitlistIds'] = waitlistIds;
          changed = true;
        } else if (event.participantIds.contains(userId)) {
           // 從參與者移除
           final participantIds = List<String>.from(event.participantIds)..remove(userId);
           final participantStatus = Map<String, dynamic>.from(event.participantStatus);
           participantStatus.remove(userId);

           updates['participantIds'] = participantIds;
           updates['participantStatus'] = participantStatus;

           // 候補遞補邏輯
           if (event.waitlistIds.isNotEmpty) {
             final firstWaiter = event.waitlistIds.first;
             final waitlistIds = List<String>.from(event.waitlistIds)..removeAt(0);

             participantIds.add(firstWaiter);
             participantStatus[firstWaiter] = 'confirmed';

             updates['waitlistIds'] = waitlistIds;
             updates['participantIds'] = participantIds;
             updates['participantStatus'] = participantStatus;
           } else {
             // 如果沒有候補，且人數少於 MAX_PARTICIPANTS，且狀態為 confirmed，可能需要變回 pending
             // 但如果已經 confirmed，通常除非太少人否則不取消。這裡保留原邏輯：
             if (event.status == EventStatus.confirmed && participantIds.length < MAX_PARTICIPANTS) {
               updates['status'] = EventStatus.pending.name;
             }

             if (participantIds.isEmpty) {
                updates['status'] = EventStatus.cancelled.name;
             }
           }
           changed = true;
        }

        if (!changed) {
          throw Exception('您未加入此活動');
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
              event.participantIds.length < MAX_PARTICIPANTS &&
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
        
        if (data['district'] != district) continue;
        
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
        // 默認截止時間：活動前 24 小時
        registrationDeadline: date.subtract(const Duration(hours: 24)),
      );
      
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }
}
