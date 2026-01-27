import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數 (預設)
  static const int DEFAULT_MAX_PARTICIPANTS = 6;

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = DEFAULT_MAX_PARTICIPANTS,
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
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        participantIds: participantIds,
        participantStatus: participantStatus,
        maxParticipants: maxParticipants,
        waitingList: [],
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

  /// 獲取用戶參與的活動列表（包含參與中和候補中）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 查詢參與的活動
      Query query1 = _eventsCollection.where('participantIds', arrayContains: userId);

      // 查詢候補的活動
      Query query2 = _eventsCollection.where('waitingList', arrayContains: userId);

      if (status != null) {
        final statusStr = status.toString().split('.').last;
        query1 = query1.where('status', isEqualTo: statusStr);
        query2 = query2.where('status', isEqualTo: statusStr);
      }

      final results = await Future.wait([query1.get(), query2.get()]);

      final Map<String, DinnerEventModel> eventsMap = {};
      
      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          final event = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          eventsMap[event.id] = event;
        }
      }

      final events = eventsMap.values.toList();
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
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

        if (event.waitingList.contains(userId)) {
          throw Exception('您已在等候名單中');
        }

        if (event.isRegistrationClosed) {
          throw Exception('報名已截止');
        }

        if (event.isFull) {
          throw Exception('活動人數已滿，請加入等候名單');
        }

        // 更新參與者列表
        final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
        
        // 更新參與者狀態
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed';

        final updates = {
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 如果人數達到上限，更新狀態為已確認（如果是 pending）
        if (newParticipantIds.length >= event.maxParticipants && event.status == EventStatus.pending) {
          updates['status'] = 'confirmed';
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 加入等候名單
  Future<void> joinWaitlist(String eventId, String userId) async {
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

        if (event.waitingList.contains(userId)) {
          throw Exception('您已在等候名單中');
        }

        if (event.isRegistrationClosed) {
          throw Exception('報名已截止');
        }

        // 更新等候名單
        final newWaitingList = List<String>.from(event.waitingList)..add(userId);

        transaction.update(docRef, {
          'waitingList': newWaitingList,
        });
      });
    } catch (e) {
      throw Exception('加入等候名單失敗: $e');
    }
  }

  /// 退出活動（或等候名單）
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        final isParticipant = event.participantIds.contains(userId);
        final isWaiting = event.waitingList.contains(userId);

        if (!isParticipant && !isWaiting) {
          throw Exception('您未加入此活動');
        }

        final updates = <String, dynamic>{};

        if (isParticipant) {
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 如果活動原本是 confirmed 且人數減少，可能變回 pending
          // 邏輯：只有當人數少於 maxParticipants 時，才有可能變回 pending。
          // 但如果已經 confirmed，通常除非低於最小開團人數（例如4人）才變更。
          // 這裡暫時維持簡單邏輯：只要少於滿員，就變回 pending，允許其他人加入
          if (event.status == EventStatus.confirmed && newParticipantIds.length < event.maxParticipants) {
             updates['status'] = 'pending';
          }

           // 如果沒有參與者了，標記為取消
          if (newParticipantIds.isEmpty) {
            updates['status'] = 'cancelled';
          }
        }

        if (isWaiting) {
          final newWaitingList = List<String>.from(event.waitingList)..remove(userId);
          updates['waitingList'] = newWaitingList;
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
          .where('status', isEqualTo: 'pending')
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              !event.isFull &&
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
        
        final event = DinnerEventModel.fromMap(data, doc.id);
        
        if (event.participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (!event.isFull) {
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
