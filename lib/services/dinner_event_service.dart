import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/enums/event_status.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = 6,
    DateTime? registrationDeadline,
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

      final event = DinnerEventModel(
        id: docRef.id,
        creatorId: creatorId,
        dateTime: dateTime,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        maxParticipants: maxParticipants,
        participantIds: participantIds,
        participantStatus: participantStatus,
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

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 因為 Firestore 的 OR 查詢限制，我們分開查詢再合併
      // 或者查詢所有相關活動（參加或在等待名單）

      // 1. 查詢已參加的
      final participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 2. 查詢在等待名單的 (Firestore 不支持直接的 OR 數組包含查詢，需分開)
      // 簡單起見，我們先查 participantIds，然後如果需要 waitingList，可能需要客戶端過濾或多次查詢
      // 這裡我們先只返回 participantIds 中的，waitingList 功能可能需要獨立查詢

      // 優化方案：增加一個 'allUserIds' 字段包含所有相關用戶，但現在先分兩次查

      final joinedSnapshot = await participantQuery.get();

      // 注意：這個查詢可能需要索引
      final waitingSnapshot = await _eventsCollection
          .where('waitingList', arrayContains: userId)
          .get();

      final allDocs = <DocumentSnapshot>{
        ...joinedSnapshot.docs,
        ...waitingSnapshot.docs
      }.toList();

      final events = allDocs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (status != null) {
        events.removeWhere((e) => e.status != status);
      }
      
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        if (event.status == EventStatus.cancelled || event.status == EventStatus.completed) {
          throw Exception('活動已結束或取消');
        }

        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitingList.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        final participantIds = List<String>.from(event.participantIds);
        final waitingList = List<String>.from(event.waitingList);
        final participantStatus = Map<String, String>.from(event.participantStatus);
        Map<String, dynamic> updates = {};

        if (participantIds.length < event.maxParticipants) {
          // 直接加入
          participantIds.add(userId);
          participantStatus[userId] = 'confirmed';

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 滿員邏輯
          if (participantIds.length == event.maxParticipants) {
            updates['status'] = EventStatus.confirmed.name;
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 加入候補
          waitingList.add(userId);
          updates['waitingList'] = waitingList;
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

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        final participantIds = List<String>.from(event.participantIds);
        final waitingList = List<String>.from(event.waitingList);
        final participantStatus = Map<String, String>.from(event.participantStatus);
        Map<String, dynamic> updates = {};

        if (event.waitingList.contains(userId)) {
          // 從候補名單移除
          waitingList.remove(userId);
          updates['waitingList'] = waitingList;
        } else if (event.participantIds.contains(userId)) {
          // 從參與者移除
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 如果候補名單有人，自動遞補
          if (waitingList.isNotEmpty) {
            final nextUserId = waitingList.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed'; // 遞補者狀態設為已確認
            updates['waitingList'] = waitingList;
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 狀態更新邏輯
          if (event.status == EventStatus.confirmed && participantIds.length < event.maxParticipants) {
            updates['status'] = EventStatus.pending.name;
          }

          if (participantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.name;
          }
        } else {
          throw Exception('您未加入此活動');
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
    }
  }

  /// 取消活動
  Future<void> cancelEvent(String eventId) async {
     try {
      await _eventsCollection.doc(eventId).update({
        'status': EventStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('取消活動失敗: $e');
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
              !event.isFull &&
              event.dateTime.isAfter(DateTime.now())
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
  }

  Stream<DinnerEventModel?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

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
          .where('status', isEqualTo: EventStatus.pending.name)
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? 6;

        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
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
