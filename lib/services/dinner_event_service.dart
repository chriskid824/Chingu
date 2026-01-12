import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數預設值
  static const int DEFAULT_MAX_PARTICIPANTS = 6;

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
    int maxParticipants = DEFAULT_MAX_PARTICIPANTS,
  }) async {
    try {
      // 創建新的文檔引用以獲取 ID
      final docRef = _eventsCollection.doc();
      
      // 初始參與者為創建者
      final participantIds = [creatorId];
      final participantStatus = {creatorId: 'confirmed'};
      
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
        maxParticipants: maxParticipants,
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitingList: [],
        registrationDeadline: dateTime.subtract(const Duration(hours: 24)),
        status: EventStatus.pending.toStringValue(),
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

  /// 獲取用戶參與的活動列表 (包含已參加和候補)
  /// 
  /// [userId] 用戶 ID
  /// [status] 活動狀態過濾（可選）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 查詢用戶為參與者的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 查詢用戶為候補的活動
      Query waitingQuery = _eventsCollection
          .where('waitingList', arrayContains: userId);

      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status);
        waitingQuery = waitingQuery.where('status', isEqualTo: status);
      }

      final results = await Future.wait([
        participantQuery.get(),
        waitingQuery.get(),
      ]);

      final Map<String, DinnerEventModel> eventsMap = {};

      for (var querySnapshot in results) {
        for (var doc in querySnapshot.docs) {
          final event = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          eventsMap[event.id] = event;
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

  /// 加入活動 (支援候補機制)
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
        
        // 1. 檢查截止時間
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        // 2. 檢查是否已在活動中
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }
        if (event.waitingList.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 3. 處理加入邏輯
        final updates = <String, dynamic>{};
        final participantIds = List<String>.from(event.participantIds);
        final waitingList = List<String>.from(event.waitingList);
        final participantStatus = Map<String, String>.from(event.participantStatus);

        if (participantIds.length < event.maxParticipants) {
          // 還有名額，直接加入
          participantIds.add(userId);
          participantStatus[userId] = 'confirmed';

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 檢查是否滿團
          if (participantIds.length == event.maxParticipants) {
            updates['status'] = EventStatus.confirmed.toStringValue();
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 已滿，加入候補
          waitingList.add(userId);
          updates['waitingList'] = waitingList;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 退出活動 (支援候補自動遞補)
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
        
        // 檢查截止時間 (這裡只做警告或記錄，實際阻擋由 UI 決定，Service層允許退出但可能會有懲罰)
        // 本次實作暫不阻擋，懲罰邏輯在 CreditService 處理

        final participantIds = List<String>.from(event.participantIds);
        final waitingList = List<String>.from(event.waitingList);
        final participantStatus = Map<String, String>.from(event.participantStatus);
        final updates = <String, dynamic>{};

        if (participantIds.contains(userId)) {
          // 移除參與者
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 檢查是否有候補可以遞補
          if (waitingList.isNotEmpty) {
            final nextUserId = waitingList.removeAt(0); // FIFO
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed'; // 自動確認
            updates['waitingList'] = waitingList;
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 狀態檢查
          if (participantIds.isEmpty) {
             // 無人參與，取消活動
             updates['status'] = EventStatus.cancelled.toStringValue();
          } else if (event.status == EventStatus.confirmed.toStringValue() &&
                     participantIds.length < event.maxParticipants) {
             // 曾經確認但現在未滿 (且無候補)
             updates['status'] = EventStatus.pending.toStringValue();
          }

        } else if (waitingList.contains(userId)) {
          // 移除候補
          waitingList.remove(userId);
          updates['waitingList'] = waitingList;
        } else {
           throw Exception('您未加入此活動');
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
          .where('status', isEqualTo: EventStatus.pending.toStringValue())
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
          .where('status', isEqualTo: EventStatus.pending.toStringValue())
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
        
        if (event.participantIds.length < event.maxParticipants) {
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
