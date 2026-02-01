import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitlistIds: [],
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

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 這裡需要同時查詢 participantIds 和 waitlistIds
      // 但 Firestore 不支援 OR 查詢跨欄位。
      // 我們主要查詢 participantIds，waitlist 可以另外處理或在 UI 層過濾。
      // 為了完整性，我們先查參加的。

      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 另外查詢 waitlist (如果需要)
      // Query waitlistQuery = _eventsCollection.where('waitlistIds', arrayContains: userId);
      // final waitlistSnapshot = await waitlistQuery.get();
      // events.addAll(waitlistSnapshot.docs.map(...));
      // 去重...

      // 為了簡單起見，暫時只返回作為參與者的活動，Waitlist 邏輯在 MyEventsScreen 可以分開調用或優化查詢

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取用戶在候補名單的活動
  Future<List<DinnerEventModel>> getUserWaitlistEvents(String userId) async {
    try {
      Query query = _eventsCollection.where('waitlistIds', arrayContains: userId);
      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return events;
    } catch (e) {
      throw Exception('獲取候補活動列表失敗: $e');
    }
  }

  /// 檢查時間衝突
  /// 檢查用戶在指定時間 +/- 3小時內是否有其他活動
  Future<void> checkTimeConflict(String userId, DateTime dateTime) async {
    try {
      // 查詢用戶的所有活動（未來）
      // 由於 Firestore 查詢限制，我們查詢該用戶未來的所有活動，然後在內存過濾
      // 或者查詢當天的活動
      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = _eventsCollection
          .where('participantIds', arrayContains: userId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay));

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final eventDate = (doc.data() as Map<String, dynamic>)['dateTime'] as Timestamp;
        final eventDateTime = eventDate.toDate();

        // 檢查是否在 3 小時內
        final difference = eventDateTime.difference(dateTime).inHours.abs();
        if (difference < 3) {
           throw Exception('此時段您已報名其他活動');
        }
      }
    } catch (e) {
      throw e; // 拋出具體錯誤
    }
  }

  /// 報名活動 (替代 joinEvent)
  /// 處理滿員、候補、衝突檢查
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 1. 獲取活動時間進行衝突檢查
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final eventDateTime = (eventData['dateTime'] as Timestamp).toDate();

      // 2. 衝突檢查 (不在事務中，減少鎖定時間)
      await checkTimeConflict(userId, eventDateTime);

      // 3. 執行事務更新
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentModel = DinnerEventModel.fromMap(data, snapshot.id);
        
        // 檢查是否已加入
        if (currentModel.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (currentModel.waitlistIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        final updates = <String, dynamic>{};

        if (currentModel.participantIds.length < currentModel.maxParticipants) {
          // 有空位 -> 加入參與者
          final newParticipants = List<String>.from(currentModel.participantIds)..add(userId);
          final newStatus = Map<String, String>.from(currentModel.participantStatus)..[userId] = 'confirmed';

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatus;

          // 如果滿員，更新狀態 (可選，視業務邏輯而定)
          // if (newParticipants.length == currentModel.maxParticipants) { ... }
        } else {
          // 已滿 -> 加入候補
          final newWaitlist = List<String>.from(currentModel.waitlistIds)..add(userId);
          updates['waitlistIds'] = newWaitlist;

          // 這裡可以拋出一個特殊異常通知 UI 顯示 "已加入候補"，或者正常返回
          // 我們選擇正常返回，UI 根據用戶 ID 在 waitlistIds 中判斷
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (替代 leaveEvent)
  /// 處理 24h 限制、候補遞補
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentModel = DinnerEventModel.fromMap(data, snapshot.id);
        
        // 檢查 24小時限制
        final timeDifference = currentModel.dateTime.difference(DateTime.now());
        if (timeDifference.inHours < 24 && currentModel.participantIds.contains(userId)) {
          // 只有正式參與者受此限制，候補者隨時可以取消
          throw Exception('活動前 24 小時內不可取消');
        }

        final updates = <String, dynamic>{};
        bool wasParticipant = false;

        if (currentModel.participantIds.contains(userId)) {
          // 移除參與者
          wasParticipant = true;
          final newParticipants = List<String>.from(currentModel.participantIds)..remove(userId);
          final newStatus = Map<String, String>.from(currentModel.participantStatus)..remove(userId);

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatus;

          // 處理候補遞補
          if (currentModel.waitlistIds.isNotEmpty) {
            final nextUserId = currentModel.waitlistIds.first;
            final newWaitlist = List<String>.from(currentModel.waitlistIds)..removeAt(0);

            newParticipants.add(nextUserId);
            newStatus[nextUserId] = 'confirmed'; // 自動確認

            updates['participantIds'] = newParticipants;
            updates['participantStatus'] = newStatus;
            updates['waitlistIds'] = newWaitlist;

            // TODO: 觸發通知給 nextUserId (透過 Cloud Functions 監聽 document change)
          }

          // 如果沒有候補且人數歸零 (這在 24h 限制下不太可能發生，除非很久以前報名)
          if (newParticipants.isEmpty) {
             updates['status'] = 'cancelled';
          }

        } else if (currentModel.waitlistIds.contains(userId)) {
          // 移除候補
          final newWaitlist = List<String>.from(currentModel.waitlistIds)..remove(userId);
          updates['waitlistIds'] = newWaitlist;
        } else {
          throw Exception('您未報名此活動');
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      // 傳遞原始異常訊息
      if (e.toString().contains('Exception:')) {
         throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('取消失敗: $e');
    }
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
              event.currentParticipantsCount < event.maxParticipants && // 只顯示未滿的
              event.dateTime.isAfter(DateTime.now())
          )
          .toList();
    } catch (e) {
      throw Exception('獲取推薦活動失敗: $e');
    }
  }

  /// 監聽單個活動更新
  Stream<DinnerEventModel?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // 為了兼容舊代碼，保留 joinOrCreateEvent，但內部邏輯應該更新
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
      // 這裡暫時維持原樣，或者調用 registerForEvent
      // 由於 joinOrCreate 需要"查找或創建"的邏輯比較複雜，且主要用於自動配對流程
      // 我們這裡暫不修改它，避免破壞現有流程，但建議未來改用 register 流程
      return await _legacyJoinOrCreateEvent(userId, date, city, district);
  }

  Future<String> _legacyJoinOrCreateEvent(String userId, DateTime date, String city, String district) async {
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
        final max = data['maxParticipants'] ?? 6;
        
        if (participantIds.contains(userId)) return doc.id;
        
        if (participantIds.length < max) {
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
