import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/services/notification_storage_service.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;
  final NotificationStorageService _notificationService;

  DinnerEventService({
    FirebaseFirestore? firestore,
    NotificationStorageService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationStorageService();

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數 (Default)
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
      final docRef = _eventsCollection.doc();
      
      final participantIds = [creatorId];
      final participantStatus = {
        creatorId: EventRegistrationStatus.registered.toStringValue()
      };
      
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
  /// 
  /// [userId] 用戶 ID
  /// [status] 過濾特定狀態 (registered, waitlist, history/past)
  Future<List<DinnerEventModel>> getUserEvents(String userId, {String? filterType}) async {
    try {
      List<DinnerEventModel> events = [];

      // 1. 查詢已報名
      final registeredSnap = await _eventsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      // 2. 查詢候補中
      final waitlistSnap = await _eventsCollection
          .where('waitlist', arrayContains: userId)
          .get();

      final Set<String> processedIds = {};

      for (var doc in registeredSnap.docs) {
        if (processedIds.contains(doc.id)) continue;
        events.add(DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        processedIds.add(doc.id);
      }
      
      for (var doc in waitlistSnap.docs) {
        if (processedIds.contains(doc.id)) continue;
        events.add(DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        processedIds.add(doc.id);
      }

      // 在內存中過濾和排序
      final now = DateTime.now();

      if (filterType == 'waitlist') {
        events = events.where((e) => e.waitlist.contains(userId)).toList();
      } else if (filterType == 'history') {
        events = events.where((e) => e.dateTime.isBefore(now)).toList();
      } else if (filterType == 'upcoming') {
        // Upcoming includes registered and waitlist? Usually just registered confirmed.
        // Or if filterType is not specified, return all.
        // Let's assume 'upcoming' means future events where user is registered (not just waitlisted)
         events = events.where((e) => e.dateTime.isAfter(now) && e.participantIds.contains(userId)).toList();
      }

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 報名活動 (替代 joinEvent)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 1. 檢查是否已報名或在候補
        if (event.participantIds.contains(userId)) throw Exception('您已報名此活動');
        if (event.waitlist.contains(userId)) throw Exception('您已在候補名單中');

        // 2. 檢查時間衝突 (Placeholder: In a real app, query user's other events around this time)
        // 此處省略複雜查詢以保持簡單，僅檢查是否重複報名同一場

        // 3. 檢查名額
        final isFull = event.participantIds.length >= event.maxParticipants;

        if (isFull) {
          // 加入候補
          final newWaitlist = List<String>.from(event.waitlist)..add(userId);
          transaction.update(docRef, {'waitlist': newWaitlist});
        } else {
          // 加入報名
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newStatus = Map<String, String>.from(event.participantStatus);
          newStatus[userId] = EventRegistrationStatus.registered.toStringValue();

          final updates = <String, dynamic>{
            'participantIds': newParticipantIds,
            'participantStatus': newStatus,
          };

          // 如果滿員，更新狀態
          if (newParticipantIds.length >= event.maxParticipants) {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(docRef, updates);
        }
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 (替代 leaveEvent)
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        // 1. 檢查截止時間 (24小時前)
        final now = DateTime.now();
        final deadline = event.dateTime.subtract(const Duration(hours: 24));
        if (now.isAfter(deadline) && event.participantIds.contains(userId)) {
           // 如果是候補取消，隨時可以。如果是正式報名，要在24小時前。
           throw Exception('活動前24小時內不可取消報名');
        }

        bool isRemoved = false;

        // 移除邏輯
        List<String> newParticipantIds = List<String>.from(event.participantIds);
        Map<String, String> newStatus = Map<String, String>.from(event.participantStatus);
        List<String> newWaitlist = List<String>.from(event.waitlist);
        
        if (newParticipantIds.contains(userId)) {
          newParticipantIds.remove(userId);
          newStatus.remove(userId);
          isRemoved = true;

          // 候補遞補邏輯
          if (newWaitlist.isNotEmpty) {
            final promotedUserId = newWaitlist.removeAt(0); // 取出第一位
            newParticipantIds.add(promotedUserId);
            newStatus[promotedUserId] = EventRegistrationStatus.registered.toStringValue();

            // 觸發通知 (這一步在 Transaction 內只是準備數據，實際發送不能在 Transaction 內做異步 await 導致鎖過久，
            // 但 NotificationStorageService 只是寫入 Firestore，可以作為 Transaction 的一部分寫入)
            // 不過跨文檔寫入需要 transaction 對象。
            // 這裡簡單起見，我們在 Transaction 成功後發送通知，或者如果 NotificationService 支持傳入 transaction 更好。
            // 目前 NotificationService 不支持傳入 transaction。
            // 我們會在 transaction 外部發送通知。
          }

        } else if (newWaitlist.contains(userId)) {
          newWaitlist.remove(userId);
          isRemoved = true;
        } else {
          throw Exception('您未報名此活動');
        }

        final updates = <String, dynamic>{
          'participantIds': newParticipantIds,
          'participantStatus': newStatus,
          'waitlist': newWaitlist,
        };

        // 狀態更新
        if (event.status == 'confirmed' && newParticipantIds.length < event.maxParticipants) {
          updates['status'] = 'pending';
        }

        transaction.update(docRef, updates);

        // 返回被遞補的用戶 ID 以便發送通知
        return newWaitlist.length < event.waitlist.length ? event.waitlist.first : null;
      }).then((promotedUserId) {
        if (promotedUserId != null && promotedUserId is String) {
          _notificationService.createEventNotification(
            userId: promotedUserId,
            eventId: eventId,
            eventTitle: '您已成功遞補活動！',
            message: '由於有人取消，您已從候補名單轉為正式參加者。請準時出席。',
          );
        }
      });
    } catch (e) {
      throw Exception('取消失敗: $e');
    }
  }

  // --- Retrofit for backward compatibility ---

  Future<void> joinEvent(String eventId, String userId) => registerForEvent(eventId, userId);
  Future<void> leaveEvent(String eventId, String userId) => unregisterFromEvent(eventId, userId);

  // --- Helper Methods ---

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
              !event.isFull &&
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
        
        final event = DinnerEventModel.fromMap(data, doc.id);

        if (event.participantIds.contains(userId)) return doc.id;
        
        if (!event.isFull) {
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
