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
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
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
        maxParticipants: MAX_PARTICIPANTS,
        currentParticipants: 1,
        participantIds: participantIds,
        waitingList: [],
        participantStatus: participantStatus,
        registrationDeadline: dateTime.subtract(const Duration(hours: 2)), // 預設截止時間為活動前2小時
        status: 'pending',
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

  /// 獲取用戶參與的活動列表 (包含已報名和候補)
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 1. 查詢已報名的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status);
      }

      final participantSnapshot = await participantQuery.get();

      // 2. 查詢候補中的活動 (Firestore 不支持 OR 查詢 array-contains，需分開查)
      // 注意：如果 status 被指定且不是 'pending'，候補名單通常只有在活動 pending 時有意義，
      // 但為了保險起見，我們只在 status 為 null 或 pending 時查候補
      List<DocumentSnapshot> waitlistDocs = [];
      if (status == null || status == 'pending') {
         // 這裡無法直接用 arrayContains 查 waitingList 因為上面已經用了 arrayContains 查 participantIds
         // 這是 Firestore 的限制：每個查詢只能有一個 array-contains 子句。
         // 所以我們必須分開查詢
         Query waitlistQuery = _eventsCollection
            .where('waitingList', arrayContains: userId);

         if (status != null) {
           waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
         }

         final waitlistSnapshot = await waitlistQuery.get();
         waitlistDocs = waitlistSnapshot.docs;
      }

      // 合併並去重
      final allDocs = [...participantSnapshot.docs];
      final seenIds = participantSnapshot.docs.map((d) => d.id).toSet();

      for (var doc in waitlistDocs) {
        if (!seenIds.contains(doc.id)) {
          allDocs.add(doc);
        }
      }

      final events = allDocs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名活動
  /// 返回報名狀態：registered 或 waitlist
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);

        // 1. 重複報名檢查
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitingList.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 時間衝突檢查
        await _checkTimeConflict(userId, event.dateTime);

        // 3. 截止時間檢查
        if (event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!)) {
          throw Exception('報名已截止');
        }

        // 4. 滿員檢查與處理
        EventRegistrationStatus resultStatus;
        
        if (event.currentParticipants < event.maxParticipants) {
          // 有名額，直接加入
          List<String> newParticipants = List.from(event.participantIds)..add(userId);
          Map<String, String> newStatus = Map.from(event.participantStatus);
          newStatus[userId] = 'confirmed';

          final updates = {
            'participantIds': newParticipants,
            'currentParticipants': event.currentParticipants + 1,
            'participantStatus': newStatus,
          };

          // 如果滿員，更新狀態 (視需求而定，可能仍保持 pending 直到系統確認)
          if (newParticipants.length >= event.maxParticipants) {
             updates['status'] = 'confirmed';
             updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
          resultStatus = EventRegistrationStatus.registered;
        } else {
          // 滿員，加入候補
          List<String> newWaitingList = List.from(event.waitingList)..add(userId);

          transaction.update(docRef, {
            'waitingList': newWaitingList,
          });
          resultStatus = EventRegistrationStatus.waitlist;
        }

        return resultStatus;
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        // 1. 檢查是否在名單中
        bool isParticipant = event.participantIds.contains(userId);
        bool isWaiting = event.waitingList.contains(userId);
        
        if (!isParticipant && !isWaiting) {
          throw Exception('您未報名此活動');
        }

        // 2. 取消截止時間檢查 (僅針對正式參與者，候補隨時可退)
        if (isParticipant) {
          final deadline = event.dateTime.subtract(const Duration(hours: 24));
          if (DateTime.now().isAfter(deadline)) {
            throw Exception('活動前24小時內不可取消');
          }
        }

        if (isParticipant) {
          // 從參與者移除
          List<String> newParticipants = List.from(event.participantIds)..remove(userId);
          Map<String, String> newStatus = Map.from(event.participantStatus)..remove(userId);
          List<String> newWaitingList = List.from(event.waitingList);

          // 3. 自動遞補邏輯
          if (newWaitingList.isNotEmpty) {
            String promotedUserId = newWaitingList.removeAt(0);
            newParticipants.add(promotedUserId);
            newStatus[promotedUserId] = 'confirmed';

            // 發送通知給 promotedUserId
            final notifRef = _firestore.collection('users').doc(promotedUserId).collection('notifications').doc();
            transaction.set(notifRef, {
              'id': notifRef.id,
              'userId': promotedUserId,
              'type': 'event',
              'title': '活動遞補通知',
              'message': '恭喜！您已成功遞補進入 "${event.city} ${event.district}" 晚餐活動。',
              'actionType': 'view_event',
              'actionData': eventId,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          final updates = {
            'participantIds': newParticipants,
            'participantStatus': newStatus,
            'currentParticipants': newParticipants.length,
            'waitingList': newWaitingList,
          };

          // 狀態回退檢查
          if (event.status == 'confirmed' && newParticipants.length < event.maxParticipants) {
            updates['status'] = 'pending';
          }

          if (newParticipants.isEmpty) {
            updates['status'] = 'cancelled';
          }

          transaction.update(docRef, updates);
        } else {
          // 從候補移除
          List<String> newWaitingList = List.from(event.waitingList)..remove(userId);
          transaction.update(docRef, {
            'waitingList': newWaitingList,
          });
        }
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 獲取推薦的活動列表（用於配對）
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      Query query = _eventsCollection
          .where('city', isEqualTo: city)
          .where('budgetRange', isEqualTo: budgetRange)
          .where('status', isEqualTo: 'pending')
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.currentParticipants < event.maxParticipants && // 只推薦未滿的
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
          .where('status', isEqualTo: 'pending')
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (participantIds.length < maxParticipants) {
          targetEventId = doc.id;
          break;
        }
      }
      
      if (targetEventId != null) {
        await registerForEvent(targetEventId, userId); // 使用新的註冊邏輯
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

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime eventDate) async {
    // 檢查前後 3 小時內是否有其他活動
    final start = eventDate.subtract(const Duration(hours: 3));
    final end = eventDate.add(const Duration(hours: 3));

    // 這裡我們查詢用戶的所有活動，然後在內存中過濾
    // 為了效能，理想情況下應該只查詢該時間段的活動，但 Firestore 需要複合索引
    // 考慮到用戶活動數量通常不多，直接查詢後過濾是可以接受的
    final userEvents = await getUserEvents(userId);

    for (var e in userEvents) {
      // 忽略已取消或已完成的活動
      if (e.status == 'cancelled' || e.status == 'completed') continue;

      // 忽略候補中的活動（候補不視為正式衝突，但如果變成正式就要檢查，這裡暫時忽略）
      if (e.waitingList.contains(userId)) continue;

      if (e.dateTime.isAfter(start) && e.dateTime.isBefore(end)) {
        throw Exception('您在此時段已有其他活動 (${e.city} ${e.district})');
      }
    }
  }
}
