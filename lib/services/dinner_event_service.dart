import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

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
      if (!doc.exists || doc.data() == null) return null;
      return DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('獲取活動詳情失敗: $e');
    }
  }

  /// 獲取用戶參與的活動列表
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 查詢 participantIds OR waitlistIds (Firestore OR queries are limited, simplified to participantIds for now,
      // but strictly we should check both if we want to show waitlisted events in "My Events")
      // Currently index only supports participantIds array-contains.
      // To support waitlist, we might need a separate query or an 'involvedUsers' array.
      // For now, let's query participantIds. Waitlist support might require a second query or schema change.
      // Let's assume user wants to see events they are confirmed in mostly.
      // For full "My Events" including waitlist, we'll need to do two queries or add 'waitlistIds' array-contains.

      Query queryConfirmed = _eventsCollection.where('participantIds', arrayContains: userId);
      Query queryWaitlist = _eventsCollection.where('waitlistIds', arrayContains: userId);

      // Running two queries and merging
      final confirmedSnapshot = await queryConfirmed.get();
      final waitlistSnapshot = await queryWaitlist.get();

      final eventsMap = <String, DinnerEventModel>{};

      for (var doc in confirmedSnapshot.docs) {
        eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      for (var doc in waitlistSnapshot.docs) {
         eventsMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      var events = eventsMap.values.toList();
      
      if (status != null) {
        events = events.where((e) => e.status == status).toList();
      }

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 註冊活動 (替代 joinEvent)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      // 1. 檢查時間衝突 (事務外)
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('活動不存在');
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final eventTime = (eventData['dateTime'] as Timestamp).toDate();

      await _checkTimeConflict(userId, eventTime, eventId);

      // 2. 事務處理註冊
      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlistIds = List<String>.from(data['waitlistIds'] ?? []);
        final maxParticipants = data['maxParticipants'] ?? 6;

        if (participantIds.contains(userId)) {
          throw Exception('您已報名此活動');
        }
        if (waitlistIds.contains(userId)) {
           throw Exception('您已在候補名單中');
        }

        EventRegistrationStatus resultStatus;

        if (participantIds.length < maxParticipants) {
          // 有名額 -> 直接報名
          participantIds.add(userId);
          final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});
          participantStatus[userId] = 'confirmed'; // 視為已確認

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
          };

          // 滿員觸發狀態變更
          if (participantIds.length == maxParticipants) {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
          resultStatus = EventRegistrationStatus.registered;
        } else {
          // 額滿 -> 加入候補
          waitlistIds.add(userId);
          transaction.update(docRef, {'waitlistIds': waitlistIds});
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

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final eventTime = (data['dateTime'] as Timestamp).toDate();
        
        // 檢查 24小時規則
        final hoursUntilEvent = eventTime.difference(DateTime.now()).inHours;
        if (hoursUntilEvent < 24 && hoursUntilEvent >= 0) {
           // TODO: 這裡可以實作懲罰邏輯，目前暫時只拋出警告或允許但標記
           // 根據需求 "活動前24小時後不可取消"
           throw Exception('活動開始前 24 小時內不可取消');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlistIds = List<String>.from(data['waitlistIds'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        bool wasConfirmed = participantIds.contains(userId);
        bool wasWaitlisted = waitlistIds.contains(userId);

        if (!wasConfirmed && !wasWaitlisted) {
          throw Exception('您未報名此活動');
        }

        if (wasConfirmed) {
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 候補遞補邏輯
          if (waitlistIds.isNotEmpty) {
            final nextUserId = waitlistIds.removeAt(0);
            participantIds.add(nextUserId);
            participantStatus[nextUserId] = 'confirmed';
            // TODO: 發送通知給遞補用戶
          }
        } else if (wasWaitlisted) {
          waitlistIds.remove(userId);
        }

        final updates = {
          'participantIds': participantIds,
          'waitlistIds': waitlistIds,
          'participantStatus': participantStatus,
        };

        // 狀態回退邏輯 (如果有人取消且沒人候補，狀態變回 pending?)
        // 只有當原本是 confirmed 且現在人數不足 max 且沒有人候補時
        // 但通常 confirmed 後不輕易變回 pending，除非人數過少。保持 confirmed 比較好。

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('取消失敗: $e'); // 保持原始錯誤訊息
    }
  }

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime newEventTime, String newEventId) async {
    // 檢查前後 2 小時
    final start = newEventTime.subtract(const Duration(hours: 2));
    final end = newEventTime.add(const Duration(hours: 2));

    // 獲取用戶已報名的活動 (confirmed)
    // 注意：getUserEvents 內部實現了合併 waitlist，但我們只關心 confirmed 衝突
    final allEvents = await getUserEvents(userId);

    for (var event in allEvents) {
      if (event.id == newEventId) continue;
      // 只有已確認的活動才算時間衝突 (waitlist 不算佔用時間)
      if (!event.participantIds.contains(userId)) continue;
      if (event.status == 'cancelled') continue;

      if (event.dateTime.isAfter(start) && event.dateTime.isBefore(end)) {
        throw Exception('時間衝突：您在該時段附近已有其他活動');
      }
    }
  }

  /// 舊方法兼容 (轉發到 registerForEvent)
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  /// 舊方法兼容 (轉發到 unregisterFromEvent)
  Future<void> leaveEvent(String eventId, String userId) async {
    await unregisterFromEvent(eventId, userId);
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

  /// 計算本週四和下週四
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
