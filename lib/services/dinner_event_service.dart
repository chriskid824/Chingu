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
  /// 
  /// [creatorId] 創建者 ID
  /// [dateTime] 日期時間
  /// [budgetRange] 預算範圍
  /// [city] 城市
  /// [district] 地區
  /// [notes] 備註（可選）
  /// [maxParticipants] 最大參與人數（預設 6）
  /// [registrationDeadline] 報名截止時間（可選）
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = DEFAULT_MAX_PARTICIPANTS,
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
        status: EventStatus.pending, // 等待配對/開放報名
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
  /// [status] 活動狀態過濾（可選 - string format）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 這裡無法簡單用 arrayContains 查 waitlist 和 participantIds 兩個欄位
      // 所以先查參與的，再查候補的（或分兩次查詢）
      // 為了簡單，先維持只查參與者，如果需要候補名單，可能需要調整索引或查詢策略

      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 注意：這可能不會返回用戶在 waitlist 的活動
      // 如果需要顯示 waitlist 活動，應該另外查詢或改變數據結構
      // 這裡暫時保持原樣，之後可以增加 waitlist 查詢

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      // 另外查詢 waitlist
      final waitlistQuery = await _eventsCollection
          .where('waitingList', arrayContains: userId)
          .get();

      final events = <DinnerEventModel>[];

      for (var doc in querySnapshot.docs) {
        events.add(DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
      }

      for (var doc in waitlistQuery.docs) {
        // 避免重複
        if (!events.any((e) => e.id == doc.id)) {
           events.add(DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 檢查是否截止
        if (!event.canRegister) {
           throw Exception('報名已截止');
        }

        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }
        
        if (event.waitingList.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        final updates = <String, dynamic>{};
        bool isUpdated = false;

        if (event.participantIds.length < event.maxParticipants) {
          // 還有名額，直接加入
          final participantIds = List<String>.from(event.participantIds);
          participantIds.add(userId);

          final participantStatus = Map<String, dynamic>.from(event.participantStatus);
          participantStatus[userId] = 'confirmed';

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;

          // 如果人數達到上限，更新狀態為 Full
          if (participantIds.length == event.maxParticipants) {
            updates['status'] = EventStatus.full.name;
            // 如果是自動成團邏輯，可以在這裡設為 confirmed
            // 根據需求，這裡設為 full，表示滿員但還可以候補
            // 如果原邏輯是滿6人confirmed，這裡保留原邏輯：
            if (event.maxParticipants == 6) { // 假設6人晚餐是特殊邏輯
                updates['status'] = EventStatus.confirmed.name;
                updates['confirmedAt'] = FieldValue.serverTimestamp();
            }
          }
          isUpdated = true;
        } else {
          // 名額已滿，加入候補名單
          final waitingList = List<String>.from(event.waitingList);
          waitingList.add(userId);
          updates['waitingList'] = waitingList;

          // 確保狀態是 Full (如果之前是 confirmed 就不動，如果是 open 就改 full)
          if (event.status == EventStatus.open || event.status == EventStatus.pending) {
             updates['status'] = EventStatus.full.name;
          }
          isUpdated = true;
        }

        if (isUpdated) {
          transaction.update(docRef, updates);
        }
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);

        final updates = <String, dynamic>{};
        bool isUpdated = false;

        if (event.waitingList.contains(userId)) {
          // 從候補名單移除
          final waitingList = List<String>.from(event.waitingList);
          waitingList.remove(userId);
          updates['waitingList'] = waitingList;

          // 如果候補空了且還有名額（理論上不會發生，除非邏輯錯誤），狀態可能變回 Open
          // 但這裡只移除候補，狀態通常不變，除非原本是 Full 且沒候補了且沒滿人
          if (waitingList.isEmpty && event.participantIds.length < event.maxParticipants && event.status == EventStatus.full) {
             updates['status'] = EventStatus.open.name;
          }

          isUpdated = true;
        } else if (event.participantIds.contains(userId)) {
          // 從參與者移除
          final participantIds = List<String>.from(event.participantIds);
          participantIds.remove(userId);

          final participantStatus = Map<String, dynamic>.from(event.participantStatus);
          participantStatus.remove(userId);

          // 檢查候補名單是否有可以遞補的人
          final waitingList = List<String>.from(event.waitingList);
          if (waitingList.isNotEmpty) {
            final nextUserId = waitingList.removeAt(0); // 取出第一位
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed'; // 自動確認遞補者

            // TODO: 發送通知給 nextUserId

            updates['waitingList'] = waitingList;
          } else {
             // 沒有候補，人數減少
             // 如果狀態是 Full/Confirmed，可能需要變回 Open/Pending
             if (participantIds.length < event.maxParticipants) {
                // 如果原本是 Confirmed 且人數不足，變回 Pending
                if (event.status == EventStatus.confirmed) {
                   updates['status'] = EventStatus.pending.name;
                   // confirmedAt 保持原樣還是清除？通常清除或保留歷史
                } else if (event.status == EventStatus.full) {
                   updates['status'] = EventStatus.open.name;
                }
             }

             if (participantIds.isEmpty) {
               updates['status'] = EventStatus.cancelled.name;
             }
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;
          isUpdated = true;
        } else {
          throw Exception('您未加入此活動');
        }

        if (isUpdated) {
          transaction.update(docRef, updates);
        }
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
      // 查詢同城市、同預算、狀態為 pending/open 的活動
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', whereIn: ['pending', 'open']) // Support both enum names
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
          .where('status', whereIn: ['pending', 'open'])
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
        final maxParticipants = data['maxParticipants'] ?? 6;
        
        // 如果用戶已經在某個活動中，直接返回該活動 ID
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        // 找到一個未滿的活動
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
        dateTime: date,
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
