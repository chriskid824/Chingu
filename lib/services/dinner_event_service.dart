import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = 6,
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
        maxParticipants: maxParticipants,
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitingList: [],
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

  /// 獲取用戶活動（包括已報名和候補）
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 因為 array-contains 不能同時用於兩個欄位，我們需要分開查詢或在客戶端過濾
      // 這裡採用分別查詢後合併的方式

      // 1. 查詢已參加的
      Query queryParticipated = _eventsCollection.where('participantIds', arrayContains: userId);
      if (status != null) {
        queryParticipated = queryParticipated.where('status', isEqualTo: status);
      }
      final participatedSnapshot = await queryParticipated.get();

      // 2. 查詢在候補名單的 (如果需要)
      // 注意：如果 status 是 'confirmed' 或 'completed'，通常不用查 waitlist，但為了完整性我們還是處理
      Query queryWaitlist = _eventsCollection.where('waitingList', arrayContains: userId);
      if (status != null) {
        queryWaitlist = queryWaitlist.where('status', isEqualTo: status);
      }
      final waitlistSnapshot = await queryWaitlist.get();

      // 合併並去重
      final allDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in participatedSnapshot.docs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in waitlistSnapshot.docs) {
        allDocs[doc.id] = doc;
      }

      final events = allDocs.values
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 排序：最新的在前
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 檢查時間衝突
  /// 檢查該用戶在 [targetTime] 前後 2 小時內是否有其他活動
  Future<bool> _hasTimeConflict(String userId, DateTime targetTime) async {
    final startTime = targetTime.subtract(const Duration(hours: 2));
    final endTime = targetTime.add(const Duration(hours: 2));

    // 查詢用戶所有未結束的活動
    // 由於 Firestore 查詢限制，我們獲取用戶未來的活動然後在內存中過濾
    final events = await getUserEvents(userId);

    for (var event in events) {
      if (event.status == 'cancelled' || event.status == 'completed') continue;

      if (event.dateTime.isAfter(startTime) && event.dateTime.isBefore(endTime)) {
        return true;
      }
    }
    return false;
  }

  /// 報名活動 (registerForEvent)
  /// 取代舊的 joinEvent
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final eventData = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(eventData, eventId);

        // 1. 重複報名檢查
        if (event.participantIds.contains(userId) || event.waitingList.contains(userId)) {
          throw Exception('您已報名此活動');
        }

        // 2. 時間衝突檢查 (讀取操作最好在 transaction 外，但為了一致性這裡放裡面，
        // 不過 Firestore Transaction 限制讀取必須在寫入前。
        // _hasTimeConflict 內部有讀取，這在 Transaction 中調用外部異步讀取可能會導致問題或鎖定。
        // 為了安全，我們應該在 transaction 之前做這個檢查，或者只檢查 user 的文檔如果結構允許。
        // 這裡暫時假設時間衝突檢查不依賴於 transaction 鎖定的一致性，但要小心 race condition。
        // 為了嚴謹，我們先不放在 transaction 內，而是在前面檢查。)
      });

      // 在 Transaction 外進行時間衝突檢查
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');
      final targetEvent = DinnerEventModel.fromMap(eventDoc.data() as Map<String, dynamic>, eventId);

      if (await _hasTimeConflict(userId, targetEvent.dateTime)) {
        throw Exception('此時段前後2小時已有其他活動');
      }

      // 重新進入 Transaction 進行寫入
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() as Map<String, dynamic>;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingList = List<String>.from(data['waitingList'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? 6;
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        if (participantIds.contains(userId) || waitingList.contains(userId)) {
           // 再次檢查以防 race condition
           return;
        }

        if (participantIds.length < maxParticipants) {
          // 3. 未滿：直接加入
          participantIds.add(userId);
          participantStatus[userId] = 'confirmed'; // 默認確認

          final updates = <String, dynamic>{
             'participantIds': participantIds,
             'participantStatus': participantStatus,
          };

          if (participantIds.length == maxParticipants) {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
        } else {
          // 4. 已滿：加入候補名單
          waitingList.add(userId);
          transaction.update(docRef, {'waitingList': waitingList});
        }
      });

    } catch (e) {
      throw Exception('報名失敗: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// 取消報名 (unregisterFromEvent)
  /// 取代舊的 leaveEvent
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final eventDateTime = (data['dateTime'] as Timestamp).toDate();
        final now = DateTime.now();

        // 1. 取消截止時間檢查 (24小時前)
        if (eventDateTime.difference(now).inHours < 24) {
          throw Exception('活動開始前24小時內不可取消');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitingList = List<String>.from(data['waitingList'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        bool isParticipant = participantIds.contains(userId);
        bool isWaiting = waitingList.contains(userId);

        if (!isParticipant && !isWaiting) {
          throw Exception('您未報名此活動');
        }

        final updates = <String, dynamic>{};

        if (isWaiting) {
          // 只是候補，直接移除
          waitingList.remove(userId);
          updates['waitingList'] = waitingList;
        } else {
          // 是正式參與者
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 2. 自動遞補邏輯
          if (waitingList.isNotEmpty) {
             final nextUserId = waitingList.removeAt(0); // FIFO
             participantIds.add(nextUserId);
             participantStatus[nextUserId] = 'confirmed';
             // 這裡未來可以觸發通知給 nextUserId
          }

          updates['participantIds'] = participantIds;
          updates['participantStatus'] = participantStatus;
          updates['waitingList'] = waitingList;

          // 檢查活動狀態
          if (participantIds.length < (data['maxParticipants'] ?? 6) && data['status'] == 'confirmed') {
            updates['status'] = 'pending';
          }
           if (participantIds.isEmpty) {
            updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: ${e.toString().replaceAll("Exception: ", "")}');
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
              !event.isFull &&
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

  /// 智能匹配加入或創建
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // 先檢查時間衝突
      if (await _hasTimeConflict(userId, date)) {
        throw Exception('此時段已有其他活動');
      }

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
        final maxParticipants = data['maxParticipants'] ?? 6;
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (participantIds.length < maxParticipants) {
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
