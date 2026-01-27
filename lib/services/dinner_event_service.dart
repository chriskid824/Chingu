import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取用戶候補的活動列表
  Future<List<DinnerEventModel>> getUserWaitlistEvents(String userId) async {
    try {
      final querySnapshot = await _eventsCollection
          .where('waitingList', arrayContains: userId)
          .get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return events;
    } catch (e) {
      throw Exception('獲取用戶候補列表失敗: $e');
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
        
        if (participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (participantIds.length >= 6) {
          throw Exception('活動人數已滿');
        }

        // 更新參與者列表
        participantIds.add(userId);
        
        // 更新參與者狀態
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
        participantStatus[userId] = 'confirmed'; // 簡單起見，直接確認

        final updates = {
          'participantIds': participantIds,
          'participantStatus': participantStatus,
        };

        // 如果人數達到 6 人，自動確認活動
        if (participantIds.length == 6) {
          updates['status'] = 'confirmed';
          updates['confirmedAt'] = FieldValue.serverTimestamp();
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

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (!participantIds.contains(userId)) {
          throw Exception('您未加入此活動');
        }

        // 移除參與者
        participantIds.remove(userId);
        
        // 移除狀態
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
        participantStatus.remove(userId);

        final updates = {
          'participantIds': participantIds,
          'participantStatus': participantStatus,
        };

        // 如果活動人數少於 6 人且狀態為已確認，可能需要處理（暫時簡單處理：變回 pending）
        if (data['status'] == 'confirmed' && participantIds.length < 6) {
          updates['status'] = 'pending';
        }

        // 如果沒有參與者了，可以考慮刪除活動或標記為取消
        if (participantIds.isEmpty) {
          updates['status'] = 'cancelled';
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

  /// 註冊活動
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否已報名或在候補名單
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitingList.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查時間衝突
        await _checkTimeConflict(userId, event.dateTime);

        // 3. 檢查人數並更新
        final updates = <String, dynamic>{};
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);

        if (event.participantIds.length < event.maxParticipants) {
          //還有名額 -> 直接報名
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          newParticipantStatus[userId] = EventRegistrationStatus.registered.name;

          updates['participantIds'] = newParticipantIds;

          // 如果滿員，更新狀態（視需求而定，這裡維持 pending 或 confirmed）
          // 之前的邏輯是滿員自動 confirmed，這裡保留該邏輯
          if (newParticipantIds.length == event.maxParticipants) {
             // 只有當尚未 confirmed 時才更新，避免覆蓋已完成狀態
             if (event.status == 'pending') {
               updates['status'] = 'confirmed';
               updates['confirmedAt'] = FieldValue.serverTimestamp();
             }
          }
        } else {
          // 額滿 -> 加入候補
          final newWaitingList = List<String>.from(event.waitingList)..add(userId);
          newParticipantStatus[userId] = EventRegistrationStatus.waitlist.name;

          updates['waitingList'] = newWaitingList;
        }

        updates['participantStatus'] = newParticipantStatus;
        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消註冊
  Future<void> unregisterFromEvent(String eventId, String userId) async {
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
        final isWaiter = event.waitingList.contains(userId);

        if (!isParticipant && !isWaiter) {
          throw Exception('您未報名此活動');
        }

        // 2. 檢查取消截止時間 (活動前24小時)
        final now = DateTime.now();
        final deadline = event.dateTime.subtract(const Duration(hours: 24));
        if (now.isAfter(deadline)) {
           throw Exception('活動前24小時內不可取消');
        }

        final updates = <String, dynamic>{};
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);

        // 移除用戶狀態
        newParticipantStatus.remove(userId); // 或者標記為 cancelled

        if (isParticipant) {
          // 從參與者移除
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);

          // 候補遞補邏輯
          if (event.waitingList.isNotEmpty) {
            final nextUserId = event.waitingList.first;
            final newWaitingList = List<String>.from(event.waitingList)..removeAt(0);

            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = EventRegistrationStatus.registered.name;

            updates['waitingList'] = newWaitingList;

            // TODO: 發送通知給遞補上的用戶
            // print('User $nextUserId promoted from waitlist');
          } else {
             // 無人遞補，如果原本是 confirmed 且人數不足，可能需要變回 pending?
             // 暫時保留 status 不變，或是根據業務邏輯調整
             if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
               updates['status'] = 'pending';
               updates['confirmedAt'] = FieldValue.delete(); // 清除確認時間
             }
          }
          updates['participantIds'] = newParticipantIds;
        } else {
          // 從候補移除
          final newWaitingList = List<String>.from(event.waitingList)..remove(userId);
          updates['waitingList'] = newWaitingList;
        }

        updates['participantStatus'] = newParticipantStatus;
        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime newEventTime) async {
    // 簡單實作：檢查該用戶是否有同一天的活動
    // 精確實作：檢查時間區段重疊 (例如前後 3 小時)

    final startOfDay = DateTime(newEventTime.year, newEventTime.month, newEventTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 查詢用戶在該日期的所有活動
    // 注意：Firestore array-contains 只能查一個欄位。這裡需要分開查或優化數據結構。
    // 這裡我們先查日期，再過濾用戶。

    final query = await _eventsCollection
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participantIds = List<String>.from(data['participantIds'] ?? []);
      final waitingList = List<String>.from(data['waitingList'] ?? []);

      if (participantIds.contains(userId) || waitingList.contains(userId)) {
        // 發現同一天的活動
        // 如果要更精確，比對具體時間
        final eventTime = (data['dateTime'] as Timestamp).toDate();
        if (eventTime.isAtSameMomentAs(newEventTime)) {
           throw Exception('您在該時段已有其他活動');
        }
      }
    }
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



