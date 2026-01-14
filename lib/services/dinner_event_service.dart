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
        participantIds: participantIds,
        participantStatus: participantStatus,
        waitlist: [],
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
      // 複合查詢限制：Firestore 不支援直接 OR 查詢 (participantIds contains X OR waitlist contains X)
      // 所以我們先查 participantIds，如果需要 waitlist 也要另查

      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      // 獲取 waitlist (另外查詢)
      final waitlistQuery = await _eventsCollection
          .where('waitlist', arrayContains: userId)
          .get();

      final eventsMap = <String, DinnerEventModel>{};

      for (var doc in querySnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistQuery.docs) {
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

  /// 報名活動 (替代 joinEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // 0. Pre-check: 讀取活動以檢查時間衝突
      // 我們在 transaction 之外讀取以避免鎖定太多，且需要進行 Query
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');

      final targetEvent = DinnerEventModel.fromMap(eventDoc.data() as Map<String, dynamic>, eventDoc.id);

      // 檢查時間衝突 (排除當前活動ID)
      final hasConflict = await checkTimeConflict(userId, targetEvent.dateTime, excludeEventId: eventId);
      if (hasConflict) {
        throw Exception('此時段已有其他活動');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 重複報名檢查
        if (event.participantIds.contains(userId)) {
           throw Exception('您已報名此活動');
        }
        if (event.waitlist.contains(userId)) {
           throw Exception('您已在候補名單中');
        }

        // 2. 滿員檢查
        if (event.participantIds.length >= event.maxParticipants) {
          // 加入 Waitlist
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          transaction.update(docRef, {'waitlist': newWaitlist});
          return; // 完成
        }

        // 正常加入
        final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
        final newParticipantStatus = Map<String, String>.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed'; // 自動確認

        final updates = <String, dynamic>{
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 如果滿員，更新狀態
        if (newParticipantIds.length == event.maxParticipants) {
          updates['status'] = 'confirmed';
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('$e'.replaceAll('Exception: ', ''));
    }
  }

  /// 檢查時間衝突
  /// 如果同一天已有參加其他活動(非 pending/cancelled)，則視為衝突
  Future<bool> checkTimeConflict(String userId, DateTime newEventTime, {String? excludeEventId}) async {
    // 簡單邏輯：同一天不能有兩個活動
    final startOfDay = DateTime(newEventTime.year, newEventTime.month, newEventTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 查詢該用戶當天所有活動
    final query = await _eventsCollection
        .where('participantIds', arrayContains: userId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    for (var doc in query.docs) {
      // 排除當前正在查看的活動
      if (excludeEventId != null && doc.id == excludeEventId) continue;

      final data = doc.data() as Map<String, dynamic>;
      // 如果狀態是 cancelled，不算衝突
      if (data['status'] == 'cancelled') continue;

      // 否則，有衝突
      return true;
    }

    return false;
  }

  /// 取消報名 (替代 leaveEvent)
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
        bool isParticipant = event.participantIds.contains(userId);
        bool isWaitlist = event.waitlist.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未報名此活動');
        }

        // 2. 取消截止時間檢查 (活動前 24 小時)
        // 只有正式參與者受此限制
        if (isParticipant) {
          final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
          if (hoursUntilEvent < 24) {
            throw Exception('活動前 24 小時內不可取消');
          }
        }

        final updates = <String, dynamic>{};

        if (isWaitlist) {
          // 從候補移除
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        } else {
          // 從參與者移除
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          // 自動遞補邏輯
          List<String> newWaitlist = List<String>.from(event.waitlist);
          if (newWaitlist.isNotEmpty) {
            final nextUserId = newWaitlist.removeAt(0); // 取出第一位
            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed'; // 自動確認遞補者
            // TODO: 發送通知給 nextUserId (Should be handled by Cloud Function trigger on document update)
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;
          updates['waitlist'] = newWaitlist;

          // 狀態更新
          if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
            updates['status'] = 'pending';
          }
           if (newParticipantIds.isEmpty && newWaitlist.isEmpty) {
            updates['status'] = 'cancelled';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('$e'.replaceAll('Exception: ', ''));
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
              event.participantIds.length < event.maxParticipants &&
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
