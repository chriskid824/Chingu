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

      // Set deadline 24 hours before event
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
        waitlistIds: [],
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

  /// 獲取用戶參與的活動列表 (包括已報名和候補)
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 1. 查詢已參與的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 2. 查詢候補的活動
      Query waitlistQuery = _eventsCollection
          .where('waitlistIds', arrayContains: userId);

      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status.toStringValue);
        waitlistQuery = waitlistQuery.where('status', isEqualTo: status.toStringValue);
      }

      final results = await Future.wait([
        participantQuery.get(),
        waitlistQuery.get(),
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];

      // 去除重複 (理論上不應該有重複，除非數據不一致)
      final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values;

      final events = uniqueDocs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
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

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('已過報名截止時間');
        }
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.isFull) {
          throw Exception('活動人數已滿，請加入等候清單');
        }

        // 如果在等候清單中，移除
        final waitlistIds = List<String>.from(event.waitlistIds);
        waitlistIds.remove(userId);

        // 更新參與者列表
        final participantIds = List<String>.from(event.participantIds);
        participantIds.add(userId);
        
        final participantStatus = Map<String, String>.from(event.participantStatus);
        participantStatus[userId] = 'confirmed';

        final updates = {
          'participantIds': participantIds,
          'participantStatus': participantStatus,
          'waitlistIds': waitlistIds,
        };

        if (participantIds.length == 6) {
          updates['status'] = EventStatus.confirmed.toStringValue;
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e'); // $e contains the message
    }
  }

  /// 加入等候清單
  Future<void> joinWaitlist(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('已過報名截止時間');
        }

        if (event.participantIds.contains(userId)) {
          throw Exception('您已是此活動的參與者');
        }

        if (event.waitlistIds.contains(userId)) {
          throw Exception('您已在等候清單中');
        }

        final waitlistIds = List<String>.from(event.waitlistIds);
        waitlistIds.add(userId);

        transaction.update(docRef, {
          'waitlistIds': waitlistIds,
        });
      });
    } catch (e) {
      throw Exception('加入等候清單失敗: $e');
    }
  }

  /// 退出活動 (或等候清單)
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

        // 檢查是否在參與者列表中
        if (event.participantIds.contains(userId)) {
          // 退出參與者
          final participantIds = List<String>.from(event.participantIds);
          participantIds.remove(userId);

          final participantStatus = Map<String, String>.from(event.participantStatus);
          participantStatus.remove(userId);

          final waitlistIds = List<String>.from(event.waitlistIds);

          // 自動從等候清單遞補
          if (waitlistIds.isNotEmpty) {
            final nextUserId = waitlistIds.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed'; // 自動確認
            // TODO: 發送通知給 nextUserId
          }

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
            'waitlistIds': waitlistIds,
          };

          // 狀態管理
          if (event.status == EventStatus.confirmed && participantIds.length < 6) {
             // 如果遞補後還是不滿6人 (即沒有候補)，狀態變回 pending
             updates['status'] = EventStatus.pending.toStringValue;
          }

          if (participantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.toStringValue;
          }

          transaction.update(docRef, updates);

        } else if (event.waitlistIds.contains(userId)) {
          // 退出等候清單
          final waitlistIds = List<String>.from(event.waitlistIds);
          waitlistIds.remove(userId);

          transaction.update(docRef, {
            'waitlistIds': waitlistIds,
          });
        } else {
          throw Exception('您未加入此活動');
        }
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
          .where('status', isEqualTo: EventStatus.pending.toStringValue)
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
          .where('status', isEqualTo: EventStatus.pending.toStringValue)
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
