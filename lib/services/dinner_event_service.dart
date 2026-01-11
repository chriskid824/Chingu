import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/enums/event_registration_status.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:uuid/uuid.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        maxParticipants: MAX_PARTICIPANTS,
        currentParticipants: 1,
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitingList: [],
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

  /// 獲取用戶在等待清單的活動列表
  Future<List<DinnerEventModel>> getUserWaitlistedEvents(String userId) async {
    try {
      Query query = _eventsCollection
          .where('waitingList', arrayContains: userId);

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return events;
    } catch (e) {
      throw Exception('獲取等待清單活動失敗: $e');
    }
  }

  /// 報名活動 (registerForEvent)
  /// 取代舊的 joinEvent
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      // 0. 讀取活動資料以檢查時間衝突
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final eventDateTime = (eventData['dateTime'] as Timestamp).toDate();

      // 時間衝突檢查 (Check conflicts before transaction to avoid unnecessary locking)
      // 獲取用戶已參加的未結束活動
      final userEvents = await getUserEvents(userId, status: 'confirmed'); // assuming 'confirmed' or 'pending'
      final pendingEvents = await getUserEvents(userId, status: 'pending');
      final allActiveEvents = [...userEvents, ...pendingEvents];

      for (var activeEvent in allActiveEvents) {
        if (activeEvent.id == eventId) continue; // Skip same event if data inconsistency
        final diff = activeEvent.dateTime.difference(eventDateTime).inHours.abs();
        if (diff < 2) {
           // 假設活動持續2小時，如果開始時間相差小於2小時，視為衝突
           // 或者根據具體業務邏輯調整
           throw Exception('與其他已報名活動時間衝突 (${activeEvent.dateTime})');
        }
      }

      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingList = List<String>.from(data['waitingList'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
        // 1. 重複報名檢查
        if (participantIds.contains(userId)) {
           // 已經是參與者
           return EventRegistrationStatus.registered;
        }
        if (waitingList.contains(userId)) {
           // 已經在候補名單
           return EventRegistrationStatus.waitlist;
        }

        // 2. 滿員檢查
        if (participantIds.length < maxParticipants) {
          // 有名額 -> 直接加入
          participantIds.add(userId);

          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus[userId] = 'confirmed'; // 默認確認

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
            'currentParticipants': participantIds.length,
          };

          if (participantIds.length == maxParticipants) {
            updates['status'] = 'confirmed'; // 滿員自動確認
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
          return EventRegistrationStatus.registered;
        } else {
          // 滿員 -> 加入 Waitlist
          waitingList.add(userId);

          transaction.update(docRef, {
            'waitingList': waitingList,
          });
          return EventRegistrationStatus.waitlist;
        }
      });
    } catch (e) {
      // Re-throw if it's our specific exception, otherwise wrap
      if (e.toString().contains('時間衝突')) rethrow;
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (unregisterFromEvent)
  /// 取代舊的 leaveEvent
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final dateTime = (data['dateTime'] as Timestamp).toDate();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingList = List<String>.from(data['waitingList'] ?? []);

        // 3. 取消截止時間檢查 (24小時前)
        final now = DateTime.now();
        final difference = dateTime.difference(now);
        if (difference.inHours < 24 && participantIds.contains(userId)) {
          // 如果是在 24 小時內且是正式參與者，禁止取消
          throw Exception('活動前24小時內不可取消');
        }

        if (waitingList.contains(userId)) {
          // 如果只是在等待清單，隨時可以取消
          waitingList.remove(userId);
          transaction.update(docRef, {
            'waitingList': waitingList,
          });
          return;
        }

        if (participantIds.contains(userId)) {
          // 移除參與者
          participantIds.remove(userId);
          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus.remove(userId);

          // 4. 等候清單自動遞補
          if (waitingList.isNotEmpty) {
            final nextUserId = waitingList.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed'; // 遞補上位，自動確認

            // 通知遞補者
            _notifyPromotedUser(nextUserId, data['restaurantName'] ?? '晚餐活動');
          }

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
            'waitingList': waitingList,
            'currentParticipants': participantIds.length,
          };

           // 如果人數變少且沒有候補
          if (participantIds.length < (data['maxParticipants'] ?? MAX_PARTICIPANTS)) {
            if (participantIds.isEmpty) {
               updates['status'] = 'cancelled';
            }
          }

          transaction.update(docRef, updates);
        } else {
           throw Exception('您未報名此活動');
        }
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  // 模擬通知發送
  void _notifyPromotedUser(String userId, String eventName) {
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        title: '候補成功！',
        message: '您已成功遞補參加 $eventName，請準時出席。',
        type: 'event',
        createdAt: DateTime.now(),
        isRead: false,
        actionType: 'view_event',
      );

      // 這裡調用 RichNotificationService 發送本地通知 (如果是當前用戶)
      // 在實際生產環境中，這裡應該是觸發 Cloud Function 來發送 FCM 推播給 userId
      // 因為 unregisterFromEvent 通常是 A 用戶操作，B 用戶 (userId) 不一定在線上
      // 這裡僅作為本地邏輯示意

      // RichNotificationService().showNotification(notification);
      // 註解掉因為這會顯示給當前操作取消的用戶，這不對。

      print('Sending notification to $userId: ${notification.message}');
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// 為了兼容舊代碼，保留 joinEvent 但指向新邏輯
  @Deprecated('Use registerForEvent instead')
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// 為了兼容舊代碼，保留 leaveEvent 但指向新邏輯
  @Deprecated('Use unregisterFromEvent instead')
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
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
              event.currentParticipants < event.maxParticipants && // 檢查是否滿員
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
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
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
        await registerForEvent(targetEventId, userId);
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
