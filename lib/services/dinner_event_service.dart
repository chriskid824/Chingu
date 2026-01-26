import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/enums/event_registration_status.dart';

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
  /// [maxParticipants] 最大參與人數（預設 6）
  /// [registrationDeadline] 報名截止時間（預設為活動開始時間）
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
      // 創建新的文檔引用以獲取 ID
      final docRef = _eventsCollection.doc();
      
      // 初始參與者為創建者
      final participantIds = [creatorId];
      final participantStatus = {creatorId: EventRegistrationStatus.registered.name};
      
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
        maxParticipants: maxParticipants,
        currentParticipants: 1,
        participantIds: participantIds,
        participantStatus: participantStatus,
        registrationDeadline: registrationDeadline ?? dateTime,
        status: 'pending', // 等待配對
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
  /// [includeWaitlist] 是否包含等候名單中的活動
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status, bool includeWaitlist = false}) async {
    try {
      // 1. 查詢已報名的活動
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      List<DinnerEventModel> events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 2. 如果需要，查詢等候名單的活動
      if (includeWaitlist) {
        Query waitlistQuery = _eventsCollection
            .where('waitlistIds', arrayContains: userId);

        if (status != null) {
          waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
        }

        final waitlistSnapshot = await waitlistQuery.get();
        final waitlistEvents = waitlistSnapshot.docs
            .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        // 合併並不重複
        final existingIds = events.map((e) => e.id).toSet();
        for (var event in waitlistEvents) {
          if (!existingIds.contains(event.id)) {
            events.add(event);
          }
        }
      }
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<bool> _hasTimeConflict(String userId, DateTime newEventTime) async {
    // 簡單檢查：前後 2 小時內是否有其他活動
    // 這裡我們只檢查已報名的活動（waitlist 不算衝突）
    final events = await getUserEvents(userId);

    for (var event in events) {
      // 忽略已取消或完成的活動
      if (event.status == 'cancelled' || event.status == 'completed') continue;

      final diff = event.dateTime.difference(newEventTime).inMinutes.abs();
      if (diff < 120) { // 2小時內
        return true;
      }
    }
    return false;
  }

  /// 報名參加活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        // 1. 檢查是否已報名或在等候名單
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitlistIds.contains(userId)) {
          throw Exception('您已在等候名單中');
        }

        // 2. 檢查報名截止時間
        if (DateTime.now().isAfter(event.registrationDeadline)) {
          throw Exception('報名已截止');
        }

        // 3. 檢查時間衝突
        // 注意：在 Transaction 中做異步查詢可能會比較慢，但為了數據一致性
        // 這裡我們假設 _hasTimeConflict 是只讀的且不依賴於當前 transaction
        // 但 Firestore Transaction 限制：所有讀取必須在寫入之前。
        // 所以最好把這個檢查移到 transaction 外面，或者如果衝突不是很頻繁，
        // 這裡先簡單略過 transaction 鎖定其他活動的複雜性。
        // 但正確做法應該是 transaction 外檢查（可能會 race condition）
        // 鑑於這是用戶行為檢查，我們在 transaction 外部做即可。
      });

      // 3. 外部檢查時間衝突
      // 重新讀取活動以獲取時間 (雖然上面讀過了，但為了不在 transaction 裡做這個 async)
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');
      final eventData = DinnerEventModel.fromMap(eventDoc.data() as Map<String, dynamic>, eventDoc.id);

      if (await _hasTimeConflict(userId, eventData.dateTime)) {
        throw Exception('您在該時段已有其他活動');
      }

      // 4. 再次進入 Transaction 執行寫入
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('活動不存在');
        
        final data = snapshot.data() as Map<String, dynamic>;
        final currentParticipants = data['currentParticipants'] ?? 0;
        final maxParticipants = data['maxParticipants'] ?? 6;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlistIds = List<String>.from(data['waitlistIds'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        // 雙重檢查
        if (participantIds.contains(userId) || waitlistIds.contains(userId)) {
           throw Exception('您已加入此活動');
        }

        if (participantIds.length < maxParticipants) {
          // 名額未滿，直接加入
          participantIds.add(userId);
          participantStatus[userId] = EventRegistrationStatus.registered.name;
          transaction.update(docRef, {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
            'currentParticipants': currentParticipants + 1,
            // 如果滿了，更新狀態為 confirmed (可選邏輯)
             if (participantIds.length == maxParticipants)
              'status': 'confirmed',
          });
        } else {
          // 名額已滿，加入 waitlist
          waitlistIds.add(userId);
          participantStatus[userId] = EventRegistrationStatus.waitlist.name;
          transaction.update(docRef, {
            'waitlistIds': waitlistIds,
            'participantStatus': participantStatus,
          });
        }
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 取消報名
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        
        // 1. 檢查取消截止時間 (活動前 24 小時)
        final deadline = eventDate.subtract(const Duration(hours: 24));
        if (DateTime.now().isAfter(deadline)) {
          throw Exception('活動前 24 小時無法取消');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlistIds = List<String>.from(data['waitlistIds'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
        final currentParticipants = data['currentParticipants'] ?? 0;

        if (waitlistIds.contains(userId)) {
          // 如果在 waitlist，直接移除
          waitlistIds.remove(userId);
          participantStatus.remove(userId);
          transaction.update(docRef, {
            'waitlistIds': waitlistIds,
            'participantStatus': participantStatus,
          });
        } else if (participantIds.contains(userId)) {
          // 如果是正式參與者
          participantIds.remove(userId);
          participantStatus.remove(userId);
          var newCurrentParticipants = currentParticipants - 1;

          // 檢查 waitlist 是否有人可以遞補
          if (waitlistIds.isNotEmpty) {
            final nextUserId = waitlistIds.removeAt(0); // 取出第一個
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = EventRegistrationStatus.registered.name;
            newCurrentParticipants++; // 遞補後人數加回來

            // TODO: 發送通知給 nextUserId
          }

          transaction.update(docRef, {
            'participantIds': participantIds,
            'waitlistIds': waitlistIds,
            'participantStatus': participantStatus,
            'currentParticipants': newCurrentParticipants,
            // 如果人數變少且原本是 confirmed，可能需要變回 pending?
            if (newCurrentParticipants < (data['maxParticipants'] ?? 6) && waitlistIds.isEmpty)
              'status': 'pending',
          });
        } else {
          throw Exception('您未報名此活動');
        }
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 兼容舊方法，轉發到新方法
  Future<void> joinEvent(String eventId, String userId) => registerForEvent(eventId, userId);
  Future<void> leaveEvent(String eventId, String userId) => unregisterFromEvent(eventId, userId);

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
          .where('status', isEqualTo: 'pending')
          .orderBy('dateTime') // 按時間排序
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.participantIds.length < 6 &&
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
    // 如果今天是週四(4)，本週四就是今天
    // 如果今天是週五(5)，本週四是昨天（但我們只顯示未來的，所以這裡只計算日期，過濾邏輯在 UI）
    // 為了簡單，我們定義：
    // 如果今天是週四之前或週四當天，本週四 = now + (4 - weekday)
    // 如果今天是週五之後，本週四 = 下週四
    
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
      // 條件：同日期、同地點、狀態為 pending、人數未滿 6 人
      // 邏輯：系統自動分組，每桌最多 6 人。如果現有桌子都滿了，就開新桌。
      
      // TODO: 未來優化匹配算法
      // 1. Budget: 優先匹配預算範圍相近的用戶
      // 2. Gender: 嘗試平衡性別比例 (例如 3男3女)
      // 3. Age: 優先匹配年齡相近的用戶
      // 4. Match Status: 優先將互相喜歡或有潛在興趣的用戶分在同一桌
      
      // 由於 Firestore 查詢限制，我們先查城市和狀態，然後在內存中過濾
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _eventsCollection
          .where('city', isEqualTo: city)
          .where('status', isEqualTo: 'pending')
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
        
        // 如果用戶已經在某個活動中，直接返回該活動 ID
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到一個未滿的活動 (人數 < MAX_PARTICIPANTS)
        // 目前邏輯：循序填滿。找到第一個有空位的桌子就加入。
        if (participantIds.length < MAX_PARTICIPANTS) {
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



