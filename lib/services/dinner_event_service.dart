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
        waitlistIds: [],
        registrationDeadline: registrationDeadline,
        status: EventStatus.pending,
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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 由於 Firestore 查詢限制，這裡分兩次查詢：參與的和在等候名單的
      // 但簡單起見，我們先查參與者包含該用戶的
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();

      var events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 另外查詢 waitlist (如果 Firestore 索引允許，可以優化)
      // 這裡簡單做：再查一次 waitlist
      final waitlistQuery = await _eventsCollection
          .where('waitlistIds', arrayContains: userId)
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

  /// 報名活動 (替代 joinEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 1. 檢查截止時間
        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }

        // 2. 檢查是否已報名
        if (event.participantIds.contains(userId) || event.waitlistIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }

        final updates = <String, dynamic>{};
        final participantIds = List<String>.from(event.participantIds);
        final waitlistIds = List<String>.from(event.waitlistIds);
        final participantStatus = Map<String, dynamic>.from(event.participantStatus);

        // 3. 檢查容量並處理
        if (participantIds.length < MAX_PARTICIPANTS) {
          // 還有名額，直接加入
          participantIds.add(userId);
          participantStatus[userId] = 'confirmed';

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 如果滿了，更新狀態為 confirmed
          if (participantIds.length == MAX_PARTICIPANTS) {
            updates['status'] = EventStatus.confirmed.name;
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 已滿，加入候補名單
          waitlistIds.add(userId);
          updates['waitlistIds'] = waitlistIds;
        }

        transaction.update(docRef, updates);
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 1. 檢查是否報名
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlisted = event.waitlistIds.contains(userId);
        
        if (!isParticipant && !isWaitlisted) {
          throw Exception('您未報名此活動');
        }

        final updates = <String, dynamic>{};
        final participantIds = List<String>.from(event.participantIds);
        final waitlistIds = List<String>.from(event.waitlistIds);
        final participantStatus = Map<String, dynamic>.from(event.participantStatus);

        if (isWaitlisted) {
          // 如果只是候補，直接移除
          waitlistIds.remove(userId);
          updates['waitlistIds'] = waitlistIds;
        } else if (isParticipant) {
          // 如果是正式參與者
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 自動候補機制
          if (waitlistIds.isNotEmpty) {
            // 取出候補第一位
            final promotedUserId = waitlistIds.removeAt(0);

            // 加入參與者
            participantIds.add(promotedUserId);
            participantStatus[promotedUserId] = 'confirmed';

            // 這裡可以發送通知給 promotedUserId (需整合 NotificationService)
          } else {
            // 沒有候補，且人數減少，如果原本是 confirmed 且現在少於 6 人，變回 pending
            if (event.status == EventStatus.confirmed && participantIds.length < MAX_PARTICIPANTS) {
              updates['status'] = EventStatus.pending.name;
            }

            // 如果所有人都退出了
            if (participantIds.isEmpty) {
              updates['status'] = EventStatus.cancelled.name;
            }
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;
          updates['waitlistIds'] = waitlistIds;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 獲取推薦的活動列表
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', isEqualTo: EventStatus.pending.name)
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.participantIds.length < MAX_PARTICIPANTS &&
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

  /// 計算本週四和下週四的日期 (Helper)
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
        // 使用新的 register 方法
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

  // Deprecated methods for backward compatibility if needed,
  // but better to remove to force update
}
