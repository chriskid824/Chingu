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
      // Firestore 不支持跨字段的 OR 查詢，所以分兩次查詢
      // 1. 查詢已參加的活動
      Query participantQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      // 2. 查詢在候補名單的活動
      Query waitlistQuery = _eventsCollection
          .where('waitlist', arrayContains: userId);

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
  Future<bool> checkTimeConflict(String userId, DateTime dateTime) async {
    // 檢查範圍：前後 3 小時
    final start = dateTime.subtract(const Duration(hours: 3));
    final end = dateTime.add(const Duration(hours: 3));

    // 獲取用戶未來的活動（狀態為 pending 或 confirmed）
    // 這裡我們獲取所有活動然後在內存過濾，因為未來活動通常不多
    final events = await getUserEvents(userId);

    for (var event in events) {
       if (event.status == 'cancelled' || event.status == 'completed') continue;

       // 檢查是否有重疊
       if (event.dateTime.isAfter(start) && event.dateTime.isBefore(end)) {
         return true;
       }
    }
    return false;
  }

  /// 報名活動 (替代 joinEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否已報名或在候補名單
        if (event.participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (event.waitlist.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查時間衝突 (需要在此事務之外先檢查，或者在這裡簡單檢查)
        // 由於事務中不能做額外查詢，建議在調用此方法前先調用 checkTimeConflict
        // 但為了原子性，這裡只能檢查文檔內的數據。
        // 我們假設外部已經檢查過了。

        // 3. 判斷加入參加列表還是候補名單
        if (event.participantIds.length < event.maxParticipants) {
          // 加入參加者
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed'; // 預設確認

          final updates = <String, dynamic>{
            'participantIds': newParticipantIds,
            'participantStatus': newParticipantStatus,
          };

          // 如果滿員，自動確認 (視業務邏輯而定)
          if (newParticipantIds.length >= event.maxParticipants) {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
        } else {
          // 加入候補名單
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          transaction.update(docRef, {'waitlist': newWaitlist});
        }
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

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 檢查是否在名單中
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlist = event.waitlist.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未報名此活動');
        }

        // 2. 檢查取消截止時間 (僅針對正式參與者)
        if (isParticipant) {
          final now = DateTime.now();
          if (event.dateTime.difference(now).inHours < 24) {
            throw Exception('活動前 24 小時內不可取消');
          }
        }

        final updates = <String, dynamic>{};

        if (isParticipant) {
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);

          // 候補遞補邏輯
          if (event.waitlist.isNotEmpty) {
            final nextUserId = event.waitlist.first;
            final newWaitlist = List<String>.from(event.waitlist)..removeAt(0);

            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed'; // 遞補者自動確認

            updates['waitlist'] = newWaitlist;
            // TODO: 這裡應該觸發通知給 nextUserId
          } else {
            // 如果沒人遞補，且原本已確認，可能需要變回 pending?
            if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
              updates['status'] = 'pending';
            }
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;
        } else if (isWaitlist) {
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        }

        if (updates.isNotEmpty) {
          transaction.update(docRef, updates);
        }
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
      // 1. 先檢查是否有時間衝突
      if (await checkTimeConflict(userId, date)) {
        throw Exception('您在該時段已有其他活動');
      }

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
