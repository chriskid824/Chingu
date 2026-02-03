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
  static const int maxParticipants = 6;

  /// 創建新的晚餐活動
  /// 
  /// [creatorId] 創建者 ID
  /// [dateTime] 日期時間
  /// [budgetRange] 預算範圍
  /// [city] 城市
  /// [district] 地區
  /// [notes] 備註（可選）
  /// [registrationDeadline] 報名截止時間（預設為活動前 24 小時）
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
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
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitingListIds: [],
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
  /// [status] 活動狀態過濾（可選，使用 EventStatus.name）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 查詢參與的活動
      Query queryParticipant = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        queryParticipant = queryParticipant.where('status', isEqualTo: status);
      }

      final querySnapshotParticipant = await queryParticipant.get();

      // 查詢在等候清單的活動
      // 注意：Firestore 不支持 OR 查詢跨不同欄位，所以需要分開查詢或在內存合併
      // 這裡簡單起見，我們另外查詢 waitingListIds
      Query queryWaiting = _eventsCollection
          .where('waitingListIds', arrayContains: userId);

      if (status != null) {
        queryWaiting = queryWaiting.where('status', isEqualTo: status);
      }

      final querySnapshotWaiting = await queryWaiting.get();

      // 合併結果並去重
      final Map<String, DinnerEventModel> eventMap = {};

      for (var doc in querySnapshotParticipant.docs) {
        eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in querySnapshotWaiting.docs) {
        if (!eventMap.containsKey(doc.id)) {
          eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      final events = eventMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取活動歷史（包括即將到來和已結束）
  ///
  /// [userId] 用戶 ID
  Future<Map<String, List<DinnerEventModel>>> getEventHistory(String userId) async {
    try {
      final allEvents = await getUserEvents(userId);
      final now = DateTime.now();

      final upcoming = <DinnerEventModel>[];
      final past = <DinnerEventModel>[];

      for (var event in allEvents) {
        // 判斷邏輯：如果活動未取消且時間在未來，或者是已完成但評價還沒結束等
        // 簡單邏輯：根據時間和狀態
        if (event.status == EventStatus.cancelled) {
           past.add(event);
        } else if (event.dateTime.isAfter(now)) {
           upcoming.add(event);
        } else {
           past.add(event);
        }
      }

      return {
        'upcoming': upcoming,
        'past': past,
      };
    } catch (e) {
      throw Exception('獲取活動歷史失敗: $e');
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
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingListIds = List<String>.from(data['waitingListIds'] ?? []);
        final registrationDeadline = data['registrationDeadline'] != null
            ? (data['registrationDeadline'] as Timestamp).toDate()
            : null;
        
        // 檢查截止時間
        if (registrationDeadline != null && DateTime.now().isAfter(registrationDeadline)) {
          throw Exception('報名已截止');
        }

        if (participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (waitingListIds.contains(userId)) {
          throw Exception('您已在等候清單中');
        }

        final updates = <String, dynamic>{};

        if (participantIds.length >= maxParticipants) {
          // 活動已滿，加入等候清單
          waitingListIds.add(userId);
          updates['waitingListIds'] = waitingListIds;

          // 如果還沒標記為 full，標記一下
          if (data['status'] == EventStatus.pending.name) {
             updates['status'] = EventStatus.full.name;
          }
        } else {
          // 加入參與者列表
          participantIds.add(userId);

          // 更新參與者狀態
          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus[userId] = 'confirmed'; // 簡單起見，直接確認

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 如果人數達到上限，更新狀態為 full (或 confirmed 如果是系統配對邏輯)
          // 這裡依照需求，滿員可能就是 full，或者如果到了時間才 confirmed
          // 原邏輯：滿6人 confirmed
          if (participantIds.length == maxParticipants) {
            updates['status'] = EventStatus.confirmed.name; // 或 full
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 取消報名 / 退出活動
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> cancelRegistration(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingListIds = List<String>.from(data['waitingListIds'] ?? []);
        
        bool isParticipant = participantIds.contains(userId);
        bool isWaiting = waitingListIds.contains(userId);

        if (!isParticipant && !isWaiting) {
          throw Exception('您未加入此活動');
        }
        
        final updates = <String, dynamic>{};

        if (isWaiting) {
          // 從等候清單移除
          waitingListIds.remove(userId);
          updates['waitingListIds'] = waitingListIds;

          // 如果從 full 變回 pending (如果有人退出等候清單不會影響狀態，除非...)
        } else if (isParticipant) {
          // 從參與者移除
          participantIds.remove(userId);

          // 移除狀態
          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus.remove(userId);

          // **等候清單遞補邏輯**
          if (waitingListIds.isNotEmpty) {
             // 取出第一位
             String promotedUserId = waitingListIds.removeAt(0);

             // 加入參與者
             participantIds.add(promotedUserId);
             participantStatus[promotedUserId] = 'confirmed'; // 自動確認

             updates['waitingListIds'] = waitingListIds;
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 狀態更新
          // 如果原本是 confirmed/full，現在人數變少且沒有遞補，可能要變回 pending
          if ((data['status'] == EventStatus.confirmed.name || data['status'] == EventStatus.full.name) &&
              participantIds.length < maxParticipants) {
            updates['status'] = EventStatus.pending.name;
          }

          // 如果沒有參與者了，標記為取消
          if (participantIds.isEmpty) {
            updates['status'] = EventStatus.cancelled.name;
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  // 為了兼容性保留 leaveEvent，調用 cancelRegistration
  Future<void> leaveEvent(String eventId, String userId) => cancelRegistration(eventId, userId);

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
              event.participantIds.length < maxParticipants &&
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
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        // 如果用戶已經在某個活動中，直接返回該活動 ID
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到一個未滿的活動 (人數 < MAX_PARTICIPANTS)
        // 目前邏輯：循序填滿。找到第一個有空位的桌子就加入。
        if (participantIds.length < maxParticipants) {
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
