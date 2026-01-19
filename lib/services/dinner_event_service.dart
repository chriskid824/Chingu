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
        participantIds: participantIds,
        participantStatus: participantStatus,
        status: 'pending',
        createdAt: DateTime.now(),
        icebreakerQuestions: icebreakerQuestions,
        currentParticipants: 1,
        maxParticipants: MAX_PARTICIPANTS,
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

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 由於 Firestore 的限制，無法同時對兩個 array 欄位做 OR 查詢 (participantIds OR waitingListIds)
      // 因此我們分別查詢然後合併，或者只查 participantIds 並由調用端處理 waitlist
      // 這裡實現合併邏輯以支援 MyEventsScreen

      // 1. 查詢已報名的活動
      Query registeredQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 2. 查詢等候中的活動
      Query waitlistQuery = _eventsCollection
          .where('waitingListIds', arrayContains: userId);

      if (status != null) {
        registeredQuery = registeredQuery.where('status', isEqualTo: status);
        waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
      }

      final registeredDocs = await registeredQuery.get();
      final waitlistDocs = await waitlistQuery.get();

      final Map<String, DinnerEventModel> eventsMap = {};
      
      for (var doc in registeredDocs.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistDocs.docs) {
        // 避免重複
        if (!eventsMap.containsKey(doc.id)) {
           eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      final events = eventsMap.values.toList();
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名活動 (registerForEvent)
  /// 
  /// 回傳最新的狀態 (registered 或 waitlist)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      // 0. 預先檢查時間衝突 (在 Transaction 外進行以減少鎖定時間)
      final targetEventDoc = await _eventsCollection.doc(eventId).get();
      if (!targetEventDoc.exists) throw Exception('活動不存在');

      final targetEvent = DinnerEventModel.fromMap(
        targetEventDoc.data() as Map<String, dynamic>,
        eventId
      );

      final existingEvents = await getUserEvents(userId);
      for (final existingEvent in existingEvents) {
        if (existingEvent.status == 'cancelled') continue;
        if (existingEvent.id == eventId) continue;

        // 假設活動持續時間為 3 小時
        final newStart = targetEvent.dateTime;
        final newEnd = newStart.add(const Duration(hours: 3));
        final existingStart = existingEvent.dateTime;
        final existingEnd = existingStart.add(const Duration(hours: 3));

        // 判斷時間重疊: StartA < EndB && EndA > StartB
        if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
           throw Exception('時間衝突：您已報名同時段的其他活動');
        }
      }

      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        // 重建 model 以方便使用
        final event = DinnerEventModel.fromMap(data, eventId);

        // 1. 重複報名檢查
        if (event.participantIds.contains(userId)) {
           return EventRegistrationStatus.registered; // 已經報名
        }
        if (event.waitingListIds.contains(userId)) {
           return EventRegistrationStatus.waitlist; // 已經在候補
        }

        // 2. (已在 Transaction 外檢查時間衝突)

        final updates = <String, dynamic>{};
        EventRegistrationStatus resultStatus;

        // 3. 滿員檢查
        if (event.currentParticipants < event.maxParticipants) {
          // 有空位 -> 加入參加者列表
          final newIds = List<String>.from(event.participantIds)..add(userId);
          final newStatusMap = Map<String, String>.from(event.participantStatus);
          newStatusMap[userId] = 'confirmed';

          updates['participantIds'] = newIds;
          updates['participantStatus'] = newStatusMap;
          updates['currentParticipants'] = event.currentParticipants + 1;

          resultStatus = EventRegistrationStatus.registered;

          // 如果滿了，更新活動狀態
          if (newIds.length >= event.maxParticipants) {
             updates['status'] = 'confirmed';
             updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 已滿 -> 加入等候名單
          final newWaitlist = List<String>.from(event.waitingListIds)..add(userId);
          updates['waitingListIds'] = newWaitlist;

          resultStatus = EventRegistrationStatus.waitlist;
        }

        transaction.update(docRef, updates);
        return resultStatus;
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (unregisterFromEvent)
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
        bool isWaitlist = event.waitingListIds.contains(userId);

        if (!isParticipant && !isWaitlist) {
          return; // 無需處理
        }

        // 2. 取消截止時間檢查 (僅針對正式參加者)
        if (isParticipant) {
           final now = DateTime.now();
           final deadline = event.dateTime.subtract(const Duration(hours: 24));
           if (now.isAfter(deadline)) {
             throw Exception('活動前 24 小時內無法取消');
           }
        }

        final updates = <String, dynamic>{};

        if (isWaitlist) {
          // 只是候補，直接移除
          final newWaitlist = List<String>.from(event.waitingListIds)..remove(userId);
          updates['waitingListIds'] = newWaitlist;
        } else if (isParticipant) {
          // 是參加者，移除並嘗試候補遞補
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newStatusMap = Map<String, String>.from(event.participantStatus)..remove(userId);
          int newCount = event.currentParticipants - 1;

          final newWaitlist = List<String>.from(event.waitingListIds);

          // 自動遞補邏輯
          if (newWaitlist.isNotEmpty) {
             final promotedUserId = newWaitlist.removeAt(0); // 取出第一位
             newParticipantIds.add(promotedUserId);
             newStatusMap[promotedUserId] = 'confirmed'; // 自動確認
             newCount++; // 人數補回

             // TODO: Trigger notification for promoted user via Cloud Functions (onUpdate trigger)
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newStatusMap;
          updates['waitingListIds'] = newWaitlist;
          updates['currentParticipants'] = newCount;

          // 狀態檢查：如果遞補後仍不滿且原本是 confirmed，可能需要變回 pending?
          // 根據需求 "滿員後...有人取消自動遞補"，通常保持 confirmed 除非人太少
          if (newCount < event.maxParticipants && event.status == 'confirmed') {
             // Optional: 是否要降級狀態? 暫時保持，除非小於某個閾值
             // updates['status'] = 'pending';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// Deprecated: Use registerForEvent
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// Deprecated: Use unregisterFromEvent
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
  }

  /// 監聽單個活動更新
  Stream<DinnerEventModel?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
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
          .where('status', isEqualTo: 'pending')
          .orderBy('dateTime')
          .limit(20);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((event) => 
              !excludeEventIds.contains(event.id) && 
              event.currentParticipants < event.maxParticipants &&
              event.dateTime.isAfter(DateTime.now())
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
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
        
        final currentParticipants = data['currentParticipants'] ?? (data['participantIds'] as List?)?.length ?? 0;
        final maxParticipants = data['maxParticipants'] ?? MAX_PARTICIPANTS;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (currentParticipants < maxParticipants) {
          targetEventId = doc.id;
          break;
        }
      }
      
      if (targetEventId != null) {
        await registerForEvent(targetEventId, userId);
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
