import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/models/notification_model.dart';

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
        currentParticipants: 1,
        maxParticipants: MAX_PARTICIPANTS,
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

  /// 獲取用戶參與的活動列表 (包含已報名和候補)
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? status}) async {
    try {
      // 1. 查詢已報名的活動
      Query registeredQuery = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        registeredQuery = registeredQuery.where('status', isEqualTo: status);
      }

      // 2. 查詢候補的活動 (如果指定了 status 且不為 pending，可能不需要查 waitlist，但為了保險起見還是查一下)
      Query waitlistQuery = _eventsCollection
          .where('waitlist', arrayContains: userId);

      if (status != null) {
         waitlistQuery = waitlistQuery.where('status', isEqualTo: status);
      }

      final results = await Future.wait([
        registeredQuery.get(),
        waitlistQuery.get(),
      ]);

      final registeredDocs = results[0].docs;
      final waitlistDocs = results[1].docs;

      final Map<String, DinnerEventModel> eventMap = {};

      for (var doc in registeredDocs) {
        eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in waitlistDocs) {
        // 避免重複 (雖然邏輯上不應該同時存在)
        if (!eventMap.containsKey(doc.id)) {
           eventMap[doc.id] = DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      var events = eventMap.values.toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 註冊/報名活動
  /// 返回註冊狀態 (Registered 或 Waitlist)
  Future<EventRegistrationStatus> registerForEvent(String eventId, String userId) async {
    try {
      // 0. 先獲取活動時間以進行衝突檢查 (在 Transaction 外進行以避免複雜度)
      final docSnapshot = await _eventsCollection.doc(eventId).get();
      if (!docSnapshot.exists) throw Exception('活動不存在');

      final targetEvent = DinnerEventModel.fromMap(docSnapshot.data() as Map<String, dynamic>, eventId);

      // 檢查是否已報名 (簡單預檢)
      if (targetEvent.participantIds.contains(userId)) return EventRegistrationStatus.registered;
      if (targetEvent.waitlist.contains(userId)) return EventRegistrationStatus.waitlist;

      // 檢查時間衝突
      await _checkTimeConflict(userId, targetEvent.dateTime);

      return await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        
        // 1. 再次檢查重複報名 (以防併發)
        if (event.participantIds.contains(userId)) {
          return EventRegistrationStatus.registered;
        }
        if (event.waitlist.contains(userId)) {
          return EventRegistrationStatus.waitlist;
        }

        // 2. 判斷加入名單還是候補
        if (event.currentParticipants < event.maxParticipants) {
          // 加入參加者
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed';

          int newCurrentParticipants = event.currentParticipants + 1;

          Map<String, dynamic> updates = {
            'participantIds': newParticipantIds,
            'participantStatus': newParticipantStatus,
            'currentParticipants': newCurrentParticipants,
          };

          // 如果滿員且狀態為 pending，可以考慮是否變更為 confirmed (視業務邏輯而定)
          // 這裡保持原邏輯：滿6人自動確認
          if (newCurrentParticipants >= event.maxParticipants && event.status == 'pending') {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
          return EventRegistrationStatus.registered;

        } else {
          // 加入候補名單
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          transaction.update(docRef, {
            'waitlist': newWaitlist,
          });
          return EventRegistrationStatus.waitlist;
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

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        // 1. 檢查是否在名單中
        bool isParticipant = event.participantIds.contains(userId);
        bool isWaitlist = event.waitlist.contains(userId);

        if (!isParticipant && !isWaitlist) {
          throw Exception('您未報名此活動');
        }

        // 2. 檢查取消截止時間 (僅針對已報名者，候補者隨時可退)
        if (isParticipant) {
          final now = DateTime.now();
          final hoursUntilEvent = event.dateTime.difference(now).inHours;
          if (hoursUntilEvent < 24) {
             throw Exception('活動前 24 小時內不可取消');
          }
        }

        Map<String, dynamic> updates = {};

        if (isWaitlist) {
          // 直接從候補移除
          final newWaitlist = List<String>.from(event.waitlist)..remove(userId);
          updates['waitlist'] = newWaitlist;
        } else {
          // 從參加者移除
          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, String>.from(event.participantStatus)..remove(userId);
          int newCurrentParticipants = event.currentParticipants - 1;

          // 3. 處理候補遞補
          List<String> newWaitlist = List<String>.from(event.waitlist);
          if (newWaitlist.isNotEmpty) {
            final promotedUserId = newWaitlist.removeAt(0); // 取出第一位

            newParticipantIds.add(promotedUserId);
            newParticipantStatus[promotedUserId] = 'confirmed';
            newCurrentParticipants++; // 補回一人

            // 觸發通知給被遞補的人
            _createPromotionNotification(transaction, promotedUserId, event);
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;
          updates['currentParticipants'] = newCurrentParticipants;
          updates['waitlist'] = newWaitlist;

          // 狀態回退邏輯 (若有人退出且無人遞補，導致不滿員)
          if (event.status == 'confirmed' && newCurrentParticipants < event.maxParticipants) {
             updates['status'] = 'pending';
          }
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      // 重新拋出異常以便 UI 處理
      rethrow;
    }
  }

  /// 檢查時間衝突
  Future<void> _checkTimeConflict(String userId, DateTime newEventDate) async {
    // 假設活動時間為 3 小時
    final newEventEnd = newEventDate.add(const Duration(hours: 3));
    final newEventStart = newEventDate;

    // 查詢該用戶所有未取消的活動
    // 這裡可能需要優化索引，或者只查未來的活動
    // 為簡單起見，我們查詢該用戶參與的活動，並在內存中過濾日期

    // 注意：這裡無法在 Transaction 中讀取太多無關文檔，所以最好將此檢查移出 Transaction，
    // 或者接受一定程度的 Race Condition (極少發生)
    // 我們選擇在 Transaction 之前做檢查 (registerForEvent 內部調用此函數，但不在 transaction scope 內?
    // 不，_checkTimeConflict 會被 await，如果在 transaction 內調用 query 會報錯 "Firestore transactions require all reads to be executed before any writes"
    // 且 transaction 內讀取必須用 transaction.get。
    // 所以我們在 registerForEvent 的 transaction 內部無法方便地查詢"其他"活動。
    // 解決方案：先查，再開 transaction。

    final querySnapshot = await _eventsCollection
        .where('participantIds', arrayContains: userId)
        .where('dateTime', isGreaterThan: DateTime.now()) // 只查未來的
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      if (status == 'cancelled') continue;

      final eventDate = (data['dateTime'] as Timestamp).toDate();
      final eventEnd = eventDate.add(const Duration(hours: 3));

      // 檢查重疊
      // (StartA < EndB) and (EndA > StartB)
      if (newEventStart.isBefore(eventEnd) && newEventEnd.isAfter(eventDate)) {
        throw Exception('此時段已安排其他活動');
      }
    }
  }

  /// 創建遞補通知
  void _createPromotionNotification(Transaction transaction, String userId, DinnerEventModel event) {
    final notificationRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();

    final notification = NotificationModel(
      id: notificationRef.id,
      userId: userId,
      type: 'event',
      title: '候補成功！',
      message: '您已成功候補加入 ${event.city} 的晚餐活動，請準時出席。',
      actionType: 'view_event',
      actionData: event.id,
      createdAt: DateTime.now(),
    );

    transaction.set(notificationRef, notification.toMap());
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
  /// 用於快速匹配 (保留舊 API 兼容性，內部邏輯可升級)
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
        // 使用新的註冊邏輯
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
}
