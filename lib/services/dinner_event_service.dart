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

      // 預設報名截止時間為活動前 24 小時
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
      // 1. 查詢用戶是參與者的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status.toString().split('.').last);
      }

      final participantSnapshot = await participantQuery.get();

      // 2. 查詢用戶在等候名單的活動
      Query waitlistQuery = _eventsCollection
          .where('waitingListIds', arrayContains: userId);

      if (status != null) {
        waitlistQuery = waitlistQuery.where('status', isEqualTo: status.toString().split('.').last);
      }

      final waitlistSnapshot = await waitlistQuery.get();

      // 3. 合併並去重
      final eventMap = <String, DinnerEventModel>{};

      for (var doc in participantSnapshot.docs) {
        eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistSnapshot.docs) {
        eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      final events = eventMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      // 使用事務確保數據一致性
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 檢查截止時間
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitingListIds.contains(userId)) {
           throw Exception('您已在等候名單中');
        }

        if (event.participantIds.length >= MAX_PARTICIPANTS) {
          throw Exception('活動人數已滿，請加入等候名單');
        }

        // 更新參與者列表
        final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
        
        // 更新參與者狀態
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed'; // 簡單起見，直接確認

        final updates = {
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 如果人數達到 6 人，自動確認活動
        if (newParticipantIds.length == MAX_PARTICIPANTS) {
          updates['status'] = EventStatus.confirmed.toString().split('.').last;
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw e; // 重新拋出異常以便 UI 處理
    }
  }

  /// 加入等候名單
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> joinWaitlist(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在等候名單中');
        }
        
        // 檢查截止時間 (等候名單也應該遵守截止時間？通常是的)
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        final newWaitingListIds = List<String>.from(event.waitingListIds)..add(userId);

        transaction.update(docRef, {
          'waitingListIds': newWaitingListIds,
        });
      });
    } catch (e) {
      throw e;
    }
  }

  /// 退出活動或等候名單
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);

        // 檢查是否在參與者名單中
        if (event.participantIds.contains(userId)) {
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          List<String> newWaitingListIds = List<String>.from(event.waitingListIds);

          // 如果有等候名單，遞補第一位
          if (newWaitingListIds.isNotEmpty) {
            final nextUserId = newWaitingListIds.removeAt(0);
            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed'; // 自動確認遞補者
            // 這裡可以發送通知給遞補者
          }

          final updates = {
            'participantIds': newParticipantIds,
            'participantStatus': newParticipantStatus,
            'waitingListIds': newWaitingListIds,
          };

          // 狀態處理
          if (event.status == EventStatus.confirmed && newParticipantIds.length < MAX_PARTICIPANTS) {
            updates['status'] = EventStatus.pending.toString().split('.').last;
          }
          if (newParticipantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.toString().split('.').last;
          }

          transaction.update(docRef, updates);
        }
        // 檢查是否在等候名單中
        else if (event.waitingListIds.contains(userId)) {
          final newWaitingListIds = List<String>.from(event.waitingListIds)..remove(userId);
          transaction.update(docRef, {
            'waitingListIds': newWaitingListIds,
          });
        } else {
          throw Exception('您未加入此活動');
        }
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
    }
  }

  // Alias for leaveEvent
  Future<void> cancelRegistration(String eventId, String userId) => leaveEvent(eventId, userId);

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
          .where('status', isEqualTo: EventStatus.pending.toString().split('.').last)
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
          .where('status', isEqualTo: EventStatus.pending.toString().split('.').last)
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
      );
      
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }
}
