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
    int maxParticipants = MAX_PARTICIPANTS,
    DateTime? registrationDeadline,
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

      // 預設截止時間為活動前 24 小時
      final deadline = registrationDeadline ?? dateTime.subtract(const Duration(hours: 24));

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
        waitlist: [],
        registrationDeadline: deadline,
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
      // 查詢參與者或候補名單
      // Firestore 不支持 OR 查詢 (array-contains participantIds OR waitlist)
      // 所以我們主要查 participantIds，waitlist 可能需要分開查或在客戶端過濾
      // 為簡單起見，我們先查 participantIds

      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();

      // 另外查詢 waitlist
      final waitlistQuery = _eventsCollection
          .where('waitlist', arrayContains: userId);

      if (status != null) {
        // waitlistQuery = waitlistQuery.where('status', isEqualTo: status.name);
        // Can't chain query easily if reassignment type differs, but logic is same
      }

      final waitlistSnapshot = await waitlistQuery.get();

      final eventsMap = <String, DinnerEventModel>{};

      for (var doc in querySnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistSnapshot.docs) {
        if (!eventsMap.containsKey(doc.id)) {
           final event = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
           if (status == null || event.status == status) {
             eventsMap[doc.id] = event;
           }
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

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitlist.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        if (event.isRegistrationClosed) {
           throw Exception('報名已截止');
        }

        if (event.isFull) {
          throw Exception('活動人數已滿');
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

        // 如果人數達到上限，自動確認活動
        if (newParticipantIds.length >= event.maxParticipants) {
          updates['status'] = EventStatus.confirmed.name;
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 加入候補名單
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

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitlist.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        if (event.isRegistrationClosed) {
           throw Exception('報名已截止');
        }

        final newWaitlist = List<String>.from(event.waitlist)..add(userId);

        transaction.update(docRef, {
          'waitlist': newWaitlist
        });
       });
    } catch (e) {
      throw Exception('加入候補名單失敗: $e');
    }
  }

  /// 退出活動 (或候補名單)
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

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        final updates = <String, dynamic>{};

        // Case 1: 用戶在候補名單
        if (event.waitlist.contains(userId)) {
           final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
           updates['waitlist'] = newWaitlist;
           transaction.update(docRef, updates);
           return;
        }

        // Case 2: 用戶在參與者名單
        if (!event.participantIds.contains(userId)) {
          throw Exception('您未加入此活動');
        }

        // 移除參與者
        final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
        
        // 移除狀態
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus.remove(userId);

        // 候補名單遞補邏輯
        final newWaitlist = List<String>.from(event.waitlist);
        if (newWaitlist.isNotEmpty && !event.isRegistrationClosed) {
          final nextUserId = newWaitlist.removeAt(0);
          newParticipantIds.add(nextUserId);
          newParticipantStatus[nextUserId] = 'confirmed'; // 自動確認遞補者
          updates['waitlist'] = newWaitlist;
        }

        updates['participantIds'] = newParticipantIds;
        updates['participantStatus'] = newParticipantStatus;

        // 如果活動人數少於 maxParticipants 且狀態為已確認，可能需要處理
        // 但如果有候補遞補，可能還是滿的。
        // 如果遞補後還是不滿 (waitlist 空了)，變回 pending
        if (event.status == EventStatus.confirmed && newParticipantIds.length < event.maxParticipants) {
          updates['status'] = EventStatus.pending.name;
        }

        // 如果沒有參與者了，標記為取消
        if (newParticipantIds.isEmpty) {
          updates['status'] = EventStatus.cancelled.name;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
    }
  }

  /// 取消報名 (Alias for leaveEvent)
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
          .where('status', isEqualTo: EventStatus.pending.name)
          .orderBy('dateTime') // 按時間排序
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              !event.isFull &&
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
    
    // 計算本週四
    // weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    DateTime thisThursday;
    if (now.weekday <= DateTime.thursday) {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday));
    } else {
      // 已經過了週四，本週四算下週的
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday + 7));
    }
    
    // 設定時間為晚上 7 點 (19:00)
    thisThursday = DateTime(
      thisThursday.year,
      thisThursday.month,
      thisThursday.day,
      19,
      0,
    );
    
    // 下週四 = 本週四 + 7天
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
      // 1. 搜尋現有符合條件的活動
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _eventsCollection
          .where('city', isEqualTo: city)
          .where('status', isEqualTo: EventStatus.pending.name)
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // 1. 檢查地區
        if (data['district'] != district) continue;
        
        // 2. 檢查日期時間
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final event = DinnerEventModel.fromMap(data, doc.id);
        
        // 如果用戶已經在某個活動中，直接返回該活動 ID
        if (event.participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到一個未滿的活動
        if (!event.isFull) {
          targetEventId = doc.id;
          break; // 找到一個就夠了
        }
      }
      
      // 2. 如果找到活動，加入它
      if (targetEventId != null) {
        await joinEvent(targetEventId, userId);
        return targetEventId;
      }
      
      // 3. 如果沒找到（或都滿了），創建新活動（開新桌）
      return await createEvent(
        creatorId: userId,
        dateTime: date, // 使用傳入的準確時間 (19:00)
        budgetRange: 1, // 預設 500-800
        city: city,
        district: district,
        notes: '週四固定晚餐聚會',
      );
      
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }
}
