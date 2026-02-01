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
      
      // 計算報名截止時間：週四活動的前一個週一晚上 23:59:59
      final monday = DateTime(dateTime.year, dateTime.month, dateTime.day).subtract(const Duration(days: 3));
      final registrationDeadline = DateTime(monday.year, monday.month, monday.day, 23, 59, 59);

      // 預設破冰問題
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
        maxParticipants: MAX_PARTICIPANTS,
        waitlist: [],
        registrationDeadline: registrationDeadline,
        status: EventStatus.pending.toFirestore(),
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
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('獲取活動詳情失敗: $e');
    }
  }

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      Query query = _eventsCollection.where('participantIds', arrayContains: userId);
      if (status != null) query = query.where('status', isEqualTo: status);

      final querySnapshot = await query.get();
      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取用戶活動歷史（包含已參加和候補）
  Future<List<DinnerEventModel>> getEventHistory(String userId) async {
    try {
      final participantEvents = await getUserEvents(userId);
      final waitlistSnapshot = await _eventsCollection
          .where('waitlist', arrayContains: userId)
          .get();

      final waitlistEvents = waitlistSnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final allEventsMap = <String, DinnerEventModel>{};
      for (var event in participantEvents) allEventsMap[event.id] = event;
      for (var event in waitlistEvents) allEventsMap[event.id] = event;

      final allEvents = allEventsMap.values.toList();
      allEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return allEvents;
    } catch (e) {
      throw Exception('獲取活動歷史失敗: $e');
    }
  }

  /// 加入活動
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        // 1. 檢查截止時間
        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }

        // 2. 檢查狀態
        if (event.eventStatus == EventStatus.cancelled || event.eventStatus == EventStatus.completed || event.eventStatus == EventStatus.closed) {
           throw Exception('此活動無法報名');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);

        if (participantIds.contains(userId)) throw Exception('您已加入此活動');
        if (waitlist.contains(userId)) throw Exception('您已在候補名單中');

        final updates = <String, dynamic>{};

        if (participantIds.length < event.maxParticipants) {
          // 加入參與者
          participantIds.add(userId);

          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus[userId] = 'confirmed';

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          if (participantIds.length >= event.maxParticipants) {
            updates['status'] = EventStatus.full.toFirestore();
          } else {
             // 如果原本是 full 但有人退出，然後現在又加入，可能需要確保狀態正確，但這裡假設正常加入流程
             // 如果人數剛好滿，設為 full。如果不滿，保持 pending 或 confirmed?
             // 邏輯: 只要不滿，就是 pending (等待配對) 或 confirmed (如果已經確認開團)
             // 這裡先不改動既有的 status 邏輯，除非變 full
          }

          // 如果人數達到 maxParticipants (預設6人)，且尚未確認，則確認活動
          // (原邏輯：滿6人自動 confirmed)
          if (participantIds.length == event.maxParticipants && data['status'] == EventStatus.pending.toFirestore()) {
             updates['status'] = EventStatus.confirmed.toFirestore(); // 原邏輯優先：滿人即成團
             updates['confirmedAt'] = FieldValue.serverTimestamp();
          } else if (participantIds.length == event.maxParticipants) {
             updates['status'] = EventStatus.full.toFirestore(); // 如果已經 confirmed，則標記為 full
          }

        } else {
          // 加入候補
          waitlist.add(userId);
          updates['waitlist'] = waitlist;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 退出活動
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);
        
        final updates = <String, dynamic>{};
        bool isParticipant = participantIds.contains(userId);
        bool isWaitlist = waitlist.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未加入此活動');
        }

        if (isParticipant) {
          participantIds.remove(userId);
          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus.remove(userId);

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 狀態處理
          final currentStatus = data['status'];
          if (currentStatus == EventStatus.full.toFirestore() || currentStatus == EventStatus.confirmed.toFirestore()) {
            if (participantIds.length < (data['maxParticipants'] ?? MAX_PARTICIPANTS)) {
              // 如果有人退出，且人數低於上限，解鎖滿員狀態
              // 如果原本是 confirmed (已成團)，保持 confirmed 但允許新人加入?
              // 或者變回 pending?
              // 策略：如果 confirmed，保持 confirmed，但因為有空位，所以不是 full。
              // 如果是 full，一定要變回 confirmed 或 pending。

              if (currentStatus == EventStatus.full.toFirestore()) {
                 // 檢查是否已經 confirmedAt
                 if (data['confirmedAt'] != null) {
                    updates['status'] = EventStatus.confirmed.toFirestore();
                 } else {
                    updates['status'] = EventStatus.pending.toFirestore();
                 }
              }
            }
          }

          if (participantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.toFirestore();
          }
        } else if (isWaitlist) {
          waitlist.remove(userId);
          updates['waitlist'] = waitlist;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
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
          .where('status', isEqualTo: EventStatus.pending.toFirestore())
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
    thisThursday = DateTime(thisThursday.year, thisThursday.month, thisThursday.day, 19, 0);
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
          .where('status', isEqualTo: EventStatus.pending.toFirestore())
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
        if (participantIds.contains(userId)) return doc.id;
        
        if (participantIds.length < maxParticipants) {
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
