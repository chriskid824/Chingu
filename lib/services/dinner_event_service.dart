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

      // 預設截止時間：活動前 2 小時
      final registrationDeadline = dateTime.subtract(const Duration(hours: 2));

      final event = DinnerEventModel(
        id: docRef.id,
        creatorId: creatorId,
        dateTime: dateTime,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        maxParticipants: MAX_PARTICIPANTS,
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitingListIds: [],
        registrationDeadline: registrationDeadline,
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
      // 查詢用戶參與或在候補名單中的活動
      // Firestore 不支持同時查詢兩個 arrayContains，所以可能需要分開查詢或查詢一次後過濾
      // 這裡我們先查詢參與的
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();

      var events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 如果需要，也可以查詢候補名單中的活動
      // Query waitingQuery = _eventsCollection.where('waitingListIds', arrayContains: userId);
      // ...合併結果...
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取用戶所有的歷史活動（包括候補）
  Future<List<DinnerEventModel>> getUserEventHistory(String userId) async {
    try {
      // 這裡簡單實現，分別查詢參與和候補，然後合併去重
      final participantQuery = await _eventsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      final waitingQuery = await _eventsCollection
          .where('waitingListIds', arrayContains: userId)
          .get();

      final allDocs = [...participantQuery.docs, ...waitingQuery.docs];
      final uniqueDocIds = <String>{};
      final events = <DinnerEventModel>[];

      for (var doc in allDocs) {
        if (uniqueDocIds.contains(doc.id)) continue;
        uniqueDocIds.add(doc.id);
        events.add(DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
      }

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return events;
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 檢查截止時間
        if (event.isPastDeadline) {
          throw Exception('已過報名截止時間');
        }

        if (event.participantIds.length >= event.maxParticipants) {
          throw Exception('活動人數已滿，請加入候補名單');
        }

        // 更新參與者列表
        final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
        
        // 更新參與者狀態
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed';

        final updates = {
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 如果人數達到最大值，自動確認活動
        if (newParticipantIds.length == event.maxParticipants && event.status == EventStatus.pending) {
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

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);

        if (event.participantIds.contains(userId)) throw Exception('您已加入此活動');
        if (event.waitingListIds.contains(userId)) throw Exception('您已在候補名單中');

        if (event.isPastDeadline) throw Exception('已過報名截止時間');

        // 如果活動還沒滿，直接加入活動
        if (event.participantIds.length < event.maxParticipants) {
          // 這裡可以選擇拋出異常提示用戶直接加入，或者直接幫用戶加入
          // 為了 UX，我們直接幫用戶加入
          // 但由於事務限制，我們需要複製 joinEvent 的邏輯
           final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
           final newParticipantStatus = Map<String, String>.from(event.participantStatus);
           newParticipantStatus[userId] = 'confirmed';

           final updates = {
             'participantIds': newParticipantIds,
             'participantStatus': newParticipantStatus,
           };

           if (newParticipantIds.length == event.maxParticipants && event.status == EventStatus.pending) {
             updates['status'] = EventStatus.confirmed.name;
             updates['confirmedAt'] = FieldValue.serverTimestamp();
           }
           transaction.update(docRef, updates);
           return;
        }

        final newWaitingListIds = List<String>.from(event.waitingListIds)..add(userId);
        transaction.update(docRef, {'waitingListIds': newWaitingListIds});
      });
    } catch (e) {
      throw Exception('加入候補失敗: $e');
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 檢查是否在參與者中
        if (event.participantIds.contains(userId)) {
          // 移除參與者
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          final updates = <String, dynamic>{
            'participantIds': newParticipantIds,
            'participantStatus': newParticipantStatus,
          };

          // 如果有候補名單，自動遞補第一位
          if (event.waitingListIds.isNotEmpty) {
            final nextUserId = event.waitingListIds.first;
            final newWaitingListIds = List<String>.from(event.waitingListIds)..removeAt(0);

            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed'; // 遞補視為已確認

            updates['waitingListIds'] = newWaitingListIds;
            // 這裡可以發送通知給遞補上的用戶 (TODO)
          } else {
             // 如果沒有候補，且活動之前是 confirmed，現在人不夠了，可能要變回 pending
             if (event.status == EventStatus.confirmed && newParticipantIds.length < event.maxParticipants) {
               updates['status'] = EventStatus.pending.name;
               // confirmedAt 不一定要清除，看業務邏輯
             }

             // 如果沒人了，取消活動
             if (newParticipantIds.isEmpty) {
               updates['status'] = EventStatus.cancelled.name;
             }
          }

          transaction.update(docRef, updates);
          return;
        }
        
        // 檢查是否在候補名單中
        if (event.waitingListIds.contains(userId)) {
          final newWaitingListIds = List<String>.from(event.waitingListIds)..remove(userId);
          transaction.update(docRef, {'waitingListIds': newWaitingListIds});
          return;
        }

        throw Exception('您未加入此活動或候補名單');
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
              event.participantIds.length < event.maxParticipants &&
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
