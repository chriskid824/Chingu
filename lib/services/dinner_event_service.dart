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

      // 設置報名截止時間為活動開始前 24 小時
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
        status: EventStatus.pending,
        createdAt: DateTime.now(),
        registrationDeadline: registrationDeadline,
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
      // 查詢用戶在參與者列表或等候名單中的活動
      // Firestore 不支持同時查詢兩個數組包含，所以可能需要分開查詢或查詢後過濾
      // 這裡我們先查參與者，這是主要場景
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toMap());
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 另外查詢等候名單 (如果需要顯示)
      // 這裡為了性能暫時只查參與的，如果需要查 Waitlist 可以在 UI 處理或增加查詢
      final waitlistQuery = await _eventsCollection
          .where('waitlist', arrayContains: userId)
          .get();

      final waitlistEvents = waitlistQuery.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((e) => !events.any((existing) => existing.id == e.id)) // 避免重複
          .toList();

      events.addAll(waitlistEvents);
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動 (或等候名單)
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

        // 檢查截止時間
        if (event.registrationDeadline != null &&
            DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitlist.contains(userId)) {
          throw Exception('您已在等候名單中');
        }

        final updates = <String, dynamic>{};

        if (event.participantIds.length >= MAX_PARTICIPANTS) {
          // 加入等候名單
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          updates['waitlist'] = newWaitlist;
        } else {
          // 加入參與者
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed'; // 自動確認

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 如果人數剛好滿了，更新狀態 (如果是 pending 的話)
          if (newParticipantIds.length == MAX_PARTICIPANTS && event.status == EventStatus.pending) {
            updates['status'] = EventStatus.confirmed.toMap();
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 退出活動 (取消報名)
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

        if (event.waitlist.contains(userId)) {
          // 從等候名單移除
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        } else if (event.participantIds.contains(userId)) {
          // 從參與者移除
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus.remove(userId);

          // 檢查是否有等候名單可以遞補
          final newWaitlist = List<String>.from(event.waitlist);
          if (newWaitlist.isNotEmpty) {
            final promotedUserId = newWaitlist.removeAt(0);
            newParticipantIds.add(promotedUserId);
            newParticipantStatus[promotedUserId] = 'confirmed'; // 自動遞補確認

            updates['waitlist'] = newWaitlist;
            // TODO: 發送通知給遞補成功的用戶
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 狀態管理
          // 如果是 confirmed 且人數不足 6 且沒有遞補 -> 變回 pending
          // 註：如果有遞補，人數維持 6，狀態不變
          if (event.status == EventStatus.confirmed && newParticipantIds.length < MAX_PARTICIPANTS) {
            updates['status'] = EventStatus.pending.toMap();
          }

          // 如果沒有參與者了 -> cancelled
          if (newParticipantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.toMap();
          }
        } else {
          throw Exception('您未參加此活動');
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
          .where('status', isEqualTo: EventStatus.pending.toMap())
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.participantIds.length < 6 &&
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

  /// 加入或創建活動
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
          .where('status', isEqualTo: EventStatus.pending.toMap())
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
