import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/enums/event_status.dart';

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
        registrationDeadline: dateTime.subtract(const Duration(hours: 24)),
        status: EventStatus.open,
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

  /// 獲取用戶參與的活動列表 (包括已報名和候補)
  /// 
  /// [userId] 用戶 ID
  /// [status] 活動狀態過濾（可選）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 查詢參與的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 查詢候補的活動
      Query waitlistQuery = _eventsCollection
          .where('waitlistIds', arrayContains: userId);

      if (status != null) {
        final statusStr = status.toStringValue();
        participantQuery = participantQuery.where('status', isEqualTo: statusStr);
        waitlistQuery = waitlistQuery.where('status', isEqualTo: statusStr);
      }

      // 並行執行查詢
      final results = await Future.wait([
        participantQuery.get(),
        waitlistQuery.get(),
      ]);

      final Map<String, DinnerEventModel> eventMap = {};

      // 處理參與的活動
      for (var doc in results[0].docs) {
        eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      // 處理候補的活動
      for (var doc in results[1].docs) {
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
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否已經截止
        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
           throw Exception('報名已截止');
        }

        // 2. 檢查是否已在名單中
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }
        if (event.waitlistIds.contains(userId)) {
          throw Exception('您已在等候名單中');
        }

        // 3. 判斷是加入正式名單還是等候名單
        final updates = <String, dynamic>{};
        
        if (event.participantIds.length < MAX_PARTICIPANTS) {
          // 加入正式名單
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed'; // 自動確認

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 檢查是否滿員
          if (newParticipantIds.length >= MAX_PARTICIPANTS) {
            updates['status'] = EventStatus.full.toStringValue();
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 加入等候名單
          final newWaitlistIds = List<String>.from(event.waitlistIds)..add(userId);
          updates['waitlistIds'] = newWaitlistIds;
          // 狀態保持 full 或更新為 full (如果之前不是)
          if (event.status != EventStatus.full) {
             updates['status'] = EventStatus.full.toStringValue();
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 退出活動
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否在名單中
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlisted = event.waitlistIds.contains(userId);

        if (!isParticipant && !isWaitlisted) {
          throw Exception('您未加入此活動');
        }

        // 2. 處理退出邏輯
        final updates = <String, dynamic>{};

        if (isParticipant) {
          // 檢查 24 小時限制
          final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
          if (hoursUntilEvent < 24 && event.status != EventStatus.cancelled) {
            // TODO: 實現懲罰邏輯 (這裡先拋出異常，或者允許但標記)
            throw Exception('活動開始前 24 小時內無法取消報名');
          }

          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          // 等候名單遞補邏輯
          if (event.waitlistIds.isNotEmpty) {
            final firstWaiter = event.waitlistIds.first;
            final newWaitlistIds = List<String>.from(event.waitlistIds)..removeAt(0);

            newParticipantIds.add(firstWaiter);
            newParticipantStatus[firstWaiter] = 'confirmed'; // 遞補後自動確認

            updates['waitlistIds'] = newWaitlistIds;
            // 狀態保持不變 (依然滿員)
          } else {
            // 沒有候補，名額釋出
            if (event.status == EventStatus.full) {
              updates['status'] = EventStatus.open.toStringValue();
            }
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 如果所有人退出
          if (newParticipantIds.isEmpty && event.waitlistIds.isEmpty) {
             updates['status'] = EventStatus.cancelled.toStringValue();
          }

        } else if (isWaitlisted) {
          // 只是退出等候名單，沒什麼限制
          final newWaitlistIds = List<String>.from(event.waitlistIds)..remove(userId);
          updates['waitlistIds'] = newWaitlistIds;
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
      // 查詢同城市、同預算、狀態為 open 的活動
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', isEqualTo: EventStatus.open.toStringValue())
          .orderBy('dateTime') // 按時間排序
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
          .where('status', isEqualTo: EventStatus.open.toStringValue())
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // 1. 檢查地區
        if (data['district'] != district) continue;
        
        // 2. 檢查日期時間
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
