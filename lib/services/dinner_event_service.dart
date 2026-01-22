import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/credit_service.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CreditService _creditService = CreditService();

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數 (deprecated, use model.maxParticipants)
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
        currentParticipants: 1,
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
      // 查詢用戶參加的或在等候名單中的活動
      // Firestore 不支持同時查詢兩個 array-contains，所以我們可能需要兩次查詢或分別查詢
      // 簡單起見，我們這裡先查 participantIds，然後如果需要完整列表（含 waitlist），這可能會漏掉
      // 但根據需求 'my_events_screen' 需要顯示 waiting，所以我們需要查 waitlist

      // 方法 1: 分別查詢再合併
      final participantsQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      final waitlistQuery = _eventsCollection
          .where('waitlist', arrayContains: userId);

      final results = await Future.wait([participantsQuery.get(), waitlistQuery.get()]);

      final Map<String, DinnerEventModel> eventsMap = {};

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          if (!eventsMap.containsKey(doc.id)) {
            eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
        }
      }

      var events = eventsMap.values.toList();

      if (status != null) {
        events = events.where((e) => e.status == status).toList();
      }

      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名活動 (新版)
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  /// 返回值: EventRegistrationStatus (registered 或 waitlist)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      // 1. 檢查時間衝突 (Pre-check outside transaction to reduce contention/complexity)
      final targetEventDoc = await _eventsCollection.doc(eventId).get();
      if (!targetEventDoc.exists) throw Exception('活動不存在');

      final targetEvent = DinnerEventModel.fromMap(targetEventDoc.data() as Map<String, dynamic>, eventId);
      final targetTime = targetEvent.dateTime;

      // 檢查用戶當天是否有其他活動 (前後 3 小時)
      final conflictStart = targetTime.subtract(const Duration(hours: 3));
      final conflictEnd = targetTime.add(const Duration(hours: 3));

      // 查詢該用戶所有活動進行比對
      // 由於無法直接在 query 中同時 filter arrayContains 和 time range 複雜條件 (composite index limitations might apply),
      // 且用戶活動量不大，我們獲取用戶所有未來活動進行過濾
      final userEvents = await getUserEvents(userId);
      final hasConflict = userEvents.any((e) {
         if (e.id == eventId) return false; // 排除自己
         if (e.status == 'cancelled') return false; // 排除已取消
         // 檢查時間重疊
         return e.dateTime.isAfter(conflictStart) && e.dateTime.isBefore(conflictEnd);
      });

      if (hasConflict) {
        throw Exception('您在此時段已有其他活動');
      }

      EventRegistrationStatus resultStatus = EventRegistrationStatus.none;

      // 1.5 檢查用戶信用分 (Requirement: 低信用限制:積分 < 0 時限制報名新活動)
      final credit = await _creditService.getUserCredit(userId);
      if (credit.balance < 0) {
        throw Exception('您的信用積分低於 0 分，暫時無法報名活動');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final currentModel = DinnerEventModel.fromMap(data, eventId);
        
        // 2. 重複報名檢查
        if (currentModel.participantIds.contains(userId)) {
           throw Exception('您已報名此活動');
        }
        if (currentModel.waitlist.contains(userId)) {
           throw Exception('您已在等候名單中');
        }
        
        // 3. 滿員檢查與處理
        if (currentModel.currentParticipants >= currentModel.maxParticipants) {
          // 加入 Waitlist
          final newWaitlist = List<String>.from(currentModel.waitlist)..add(userId);
          transaction.update(docRef, {
            'waitlist': newWaitlist,
          });
          resultStatus = EventRegistrationStatus.waitlist;
        } else {
          // 加入 Participants
          final newParticipants = List<String>.from(currentModel.participantIds)..add(userId);
          final newStatus = Map<String, String>.from(currentModel.participantStatus);
          newStatus[userId] = 'confirmed'; // 自動確認

          final updates = <String, dynamic>{
            'participantIds': newParticipants,
            'participantStatus': newStatus,
            'currentParticipants': newParticipants.length,
          };

          // 如果滿員，更新狀態 (optional, 視業務邏輯而定，若需湊滿才 confirm 則需調整)
          if (newParticipants.length >= currentModel.maxParticipants && currentModel.status == 'pending') {
             updates['status'] = 'confirmed';
             updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
          resultStatus = EventRegistrationStatus.registered;
        }
      });

      return resultStatus;
    } catch (e) {
      throw Exception('報名失敗: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// 取消報名 (新版)
  /// 
  /// [eventId] 活動 ID
  /// [userId] 用戶 ID
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final currentModel = DinnerEventModel.fromMap(data, eventId);

        // 1. 檢查是否報名
        final isRegistered = currentModel.participantIds.contains(userId);
        final isWaitlisted = currentModel.waitlist.contains(userId);
        
        if (!isRegistered && !isWaitlisted) {
           throw Exception('您未報名此活動');
        }
        
        // 2. 檢查取消截止時間 (僅針對已報名者，Waitlist 隨時可退)
        if (isRegistered) {
          if (!currentModel.canCancel) {
             throw Exception('活動前24小時內不可取消');
          }
        }

        final updates = <String, dynamic>{};

        if (isWaitlisted) {
          // 從 Waitlist 移除
          final newWaitlist = List<String>.from(currentModel.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        } else {
          // 從 Participants 移除
          final newParticipants = List<String>.from(currentModel.participantIds)..remove(userId);
          final newStatus = Map<String, String>.from(currentModel.participantStatus)..remove(userId);

          // 4. 自動遞補邏輯
          if (currentModel.waitlist.isNotEmpty) {
             final nextUserId = currentModel.waitlist.first;
             final newWaitlist = List<String>.from(currentModel.waitlist)..removeAt(0);

             newParticipants.add(nextUserId);
             newStatus[nextUserId] = 'confirmed';
             updates['waitlist'] = newWaitlist;

             // TODO: 觸發通知給 nextUserId (恭喜您已從候補名單轉為正式參加！)
          }

          updates['participantIds'] = newParticipants;
          updates['participantStatus'] = newStatus;
          updates['currentParticipants'] = newParticipants.length;

          // 狀態回退
          if (currentModel.status == 'confirmed' && newParticipants.length < currentModel.maxParticipants) {
             // 視業務邏輯，如果遞補了人則人數不變，若沒人遞補則變回 pending
             if (updates['waitlist'] == null || (updates['waitlist'] as List).isEmpty) {
                // updates['status'] = 'pending'; // 暫不回退狀態，避免反覆
             }
          }

          if (newParticipants.isEmpty) {
             updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消失敗: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// 加入活動 (兼容舊版，轉發到 registerForEvent)
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// 退出活動 (兼容舊版，轉發到 unregisterFromEvent)
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
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
              event.currentParticipants < event.maxParticipants &&
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
        
        final currentParticipants = data['currentParticipants'] ?? (data['participantIds'] as List).length;
        final maxParticipants = data['maxParticipants'] ?? 6;
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
