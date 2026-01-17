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

      // 預設截止時間為活動前 24 小時
      final registrationDeadline = dateTime.subtract(const Duration(hours: 24));

      final event = DinnerEventModel(
        id: docRef.id,
        creatorId: creatorId,
        dateTime: dateTime,
        registrationDeadline: registrationDeadline,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        participantIds: participantIds,
        participantStatus: participantStatus,
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

  /// 獲取用戶參與的活動列表 (包括已報名和候位)
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // Firestore 不支持同時查詢兩個 arrayContains，所以分開查或者查一個然後內存過濾
      // 這裡我們先查參與的，因為這是主要場景
      // 優化：可以將 userId 同時存放在 'all_related_users' 字段來簡化查詢，但現在先分別查

      // 1. 查已參與
      Query queryParticipating = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 2. 查候位 (如果需要完整列表，可能需要兩次查詢並合併)
      // 為簡化，暫時只返回已參與的，或者如果需要顯示候位，需要前端處理或後端增加索引
      // 這裡先實現查詢 participantIds

      if (status != null) {
        queryParticipating = queryParticipating.where('status', isEqualTo: status.toStringValue());
      }

      final querySnapshot = await queryParticipating.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 額外查詢候位的活動 (如果不太多)
      final waitlistSnapshot = await _eventsCollection
          .where('waitlist', arrayContains: userId)
          .get();

      final waitlistEvents = waitlistSnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 合併並去重
      final allEvents = {...events, ...waitlistEvents}.toList();

      // 排序
      allEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return allEvents;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitlist.contains(userId)) {
          throw Exception('您已在等候名單中，請先退出等候');
        }

        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        if (event.participantIds.length >= MAX_PARTICIPANTS) {
          throw Exception('活動人數已滿，請加入等候清單');
        }

        // 更新數據
        final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed';

        final updates = <String, dynamic>{
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 滿員確認
        if (newParticipantIds.length == MAX_PARTICIPANTS) {
          updates['status'] = EventStatus.confirmed.toStringValue();
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 加入等候清單
  Future<void> addToWaitlist(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        if (event.participantIds.contains(userId)) throw Exception('您已加入此活動');
        if (event.waitlist.contains(userId)) throw Exception('您已在等候名單中');
        
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        final newWaitlist = List<String>.from(event.waitlist)..add(userId);
        
        transaction.update(docRef, {'waitlist': newWaitlist});
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 退出活動 (或等候清單)
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        bool isParticipant = event.participantIds.contains(userId);
        bool isWaitlisted = event.waitlist.contains(userId);

        if (!isParticipant && !isWaitlisted) {
          throw Exception('您未參與此活動');
        }

        final updates = <String, dynamic>{};

        if (isParticipant) {
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 狀態變更邏輯
          if (event.status == EventStatus.confirmed && newParticipantIds.length < MAX_PARTICIPANTS) {
            updates['status'] = EventStatus.pending.toStringValue();
          }

          if (newParticipantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.toStringValue();
          }
        } else {
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 獲取推薦活動
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      final now = DateTime.now();
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', isEqualTo: EventStatus.pending.toStringValue())
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.participantIds.length < MAX_PARTICIPANTS &&
              event.dateTime.isAfter(now) &&
              event.registrationDeadline.isAfter(now) // 過了截止時間的不顯示
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

  // ... (保留 joinOrCreateEvent 和 getThursdayDates, 僅需確保使用新的 Model 和邏輯)

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
          .where('status', isEqualTo: EventStatus.pending.toStringValue())
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (participantIds.contains(userId)) return doc.id;
        
        // 檢查截止時間
        final deadline = data['registrationDeadline'] != null
            ? (data['registrationDeadline'] as Timestamp).toDate()
            : eventDate.subtract(const Duration(hours: 24));

        if (DateTime.now().isAfter(deadline)) continue;

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
