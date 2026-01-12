import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:flutter/foundation.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數預設值
  static const int DEFAULT_MAX_PARTICIPANTS = 6;

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = DEFAULT_MAX_PARTICIPANTS,
  }) async {
    try {
      // 創建新的文檔引用以獲取 ID
      final docRef = _eventsCollection.doc();
      
      // 初始參與者為創建者
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
      // 查詢已報名的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 查詢候補的活動
      Query waitlistQuery = _eventsCollection
          .where('waitingList', arrayContains: userId);

      if (status != null) {
        participantQuery = participantQuery.where('status', isEqualTo: status);
        waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
      }

      final participantSnapshot = await participantQuery.get();
      final waitlistSnapshot = await waitlistQuery.get();

      final eventsMap = <String, DinnerEventModel>{};

      for (var doc in participantSnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistSnapshot.docs) {
        // 避免重複 (雖然邏輯上不應該重複)
        if (!eventsMap.containsKey(doc.id)) {
          eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      final events = eventsMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 檢查時間衝突
  /// 
  /// 檢查用戶在 [dateTime] 前後 2 小時內是否已有其他活動
  /// 返回 true 表示有衝突
  Future<bool> hasTimeConflict(String userId, DateTime dateTime) async {
    try {
      // 獲取用戶的所有未來活動
      // 注意：這裡可能會查詢較多數據，但為了準確性必須獲取用戶所有活動
      // 理想情況下，應該只查詢當天的活動，但 Firestore 不支持跨字段 (participantIds + dateTime range) 查詢
      // 所以我們先獲取用戶所有活動，再過濾
      final userEvents = await getUserEvents(userId);

      for (var event in userEvents) {
        // 忽略已取消或完成的活動
        if (event.status == 'cancelled' || event.status == 'completed') continue;

        final diff = event.dateTime.difference(dateTime).inHours.abs();
        if (diff < 2) {
          return true; // 發現衝突 (2小時內)
        }
      }
      return false;
    } catch (e) {
      debugPrint('檢查時間衝突失敗: $e');
      return false; // 發生錯誤時預設無衝突，避免阻擋用戶
    }
  }

  /// 報名活動 (registerForEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 注意：這裡不進行時間衝突檢查，應在調用前檢查 (e.g. in Provider)
      // 因為 transaction 內不建議做耗時異步操作

      await _firestore.runTransaction((transaction) async {
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

        final updates = <String, dynamic>{};

        // 3. 滿員檢查與候補邏輯
        if (event.participantIds.length >= event.maxParticipants) {
           // 加入候補名單
           final newWaitlist = List<String>.from(event.waitingList)..add(userId);
           updates['waitingList'] = newWaitlist;
           // 這裡可以加入通知邏輯（活動滿員，您已加入候補）
        } else {
          // 加入正式名單
          final newParticipants = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed';

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newParticipantStatus;
          updates['currentParticipants'] = newParticipants.length;

          // 如果人數達到最大值，自動確認活動 (如果還沒確認)
          if (newParticipants.length >= event.maxParticipants && event.status == 'pending') {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        }

        transaction.update(docRef, updates);
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
        
        bool isParticipant = event.participantIds.contains(userId);
        bool isWaitlist = event.waitingList.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未參加此活動');
        }

        // 1. 取消截止時間檢查 (僅針對正式參與者)
        if (isParticipant) {
          final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
          if (hoursUntilEvent < 24) {
            throw Exception('活動前 24 小時內無法取消報名');
          }
        }

        final updates = <String, dynamic>{};

        if (isWaitlist) {
          // 從候補移除
          final newWaitlist = List<String>.from(event.waitingList)..remove(userId);
          updates['waitingList'] = newWaitlist;
        } else if (isParticipant) {
          // 從參與者移除
          final newParticipants = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus.remove(userId);

          // 2. 自動遞補邏輯
          if (event.waitingList.isNotEmpty) {
            final promotedUserId = event.waitingList.first;
            final newWaitlist = List<String>.from(event.waitingList)..removeAt(0);

            newParticipants.add(promotedUserId);
            newParticipantStatus[promotedUserId] = 'confirmed'; // 自動確認遞補者

            updates['waitingList'] = newWaitlist;

            // TODO: 發送通知給 promotedUserId (您已從候補名單遞補成功！)
            // 這邊只能做標記，實際發送要在 transaction 外
          }

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newParticipantStatus;
          updates['currentParticipants'] = newParticipants.length;

          // 狀態變更邏輯
          if (event.status == 'confirmed' && newParticipants.length < event.maxParticipants) {
             updates['status'] = 'pending';
          }

          if (newParticipants.isEmpty) {
             updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 為了兼容舊代碼，保留 joinEvent 但指向 registerForEvent
  Future<void> joinEvent(String eventId, String userId) async {
    return registerForEvent(eventId, userId);
  }

  /// 為了兼容舊代碼，保留 leaveEvent 但指向 unregisterFromEvent
  Future<void> leaveEvent(String eventId, String userId) async {
    return unregisterFromEvent(eventId, userId);
  }

  /// 獲取推薦的活動列表（用於配對）
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
              event.currentParticipants < event.maxParticipants &&
              event.dateTime.isAfter(DateTime.now()) // 只顯示未來的活動
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

  /// 計算本週四和下週四的日期
  List<DateTime> getThursdayDates() {
    final now = DateTime.now();
    DateTime thisThursday;
    if (now.weekday <= DateTime.thursday) {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday));
    } else {
      thisThursday = now.add(Duration(days: DateTime.thursday - now.weekday + 7));
    }
    thisThursday = DateTime(thisThursday.year, thisThursday.month, thisThursday.day, 19, 0);
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
        final maxParticipants = data['maxParticipants'] ?? DEFAULT_MAX_PARTICIPANTS;
        
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
