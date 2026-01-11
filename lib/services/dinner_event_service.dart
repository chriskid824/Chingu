import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:flutter/foundation.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
    DateTime? registrationDeadline,
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

      // 默認截止時間為活動前 4 小時
      final deadline = registrationDeadline ?? dateTime.subtract(const Duration(hours: 4));

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
        waitingListIds: [],
        registrationDeadline: deadline,
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
      Query query = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 在內存中排序
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動 (含候補機制)
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        
        // 1. 檢查是否已在名單中
        if (event.participantIds.contains(userId)) {
          throw Exception('您已參加此活動');
        }
        if (event.waitingListIds.contains(userId)) {
          throw Exception('您已在候補名單中');
        }

        // 2. 檢查截止時間
        if (event.isRegistrationClosed) {
          throw Exception('報名已截止');
        }

        // 3. 判斷加入參與者還是候補
        final updates = <String, dynamic>{};
        
        if (event.participantIds.length < event.maxParticipants) {
          // 還有名額 -> 加入參與者
          final newParticipantIds = List<String>.from(event.participantIds)..add(userId);
          final newParticipantStatus = Map<String, dynamic>.from(event.participantStatus);
          newParticipantStatus[userId] = 'confirmed'; // 預設確認

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 如果滿了，且尚未確認，則更新為確認狀態 (根據業務邏輯，這裡假設滿人即成團)
          if (newParticipantIds.length == event.maxParticipants && event.status == 'pending') {
            updates['status'] = 'confirmed';
            updates['confirmedAt'] = FieldValue.serverTimestamp();
          }
        } else {
          // 已滿 -> 加入候補
          final newWaitingList = List<String>.from(event.waitingListIds)..add(userId);
          updates['waitingListIds'] = newWaitingList;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      debugPrint('Error joining event: $e');
      rethrow;
    }
  }

  /// 退出活動 (含候補遞補機制)
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final data = snapshot.data() as Map<String, dynamic>;
        final event = DinnerEventModel.fromMap(data, eventId);
        final updates = <String, dynamic>{};

        if (event.waitingListIds.contains(userId)) {
          // 如果在候補名單，直接移除
          final newWaitingList = List<String>.from(event.waitingListIds)..remove(userId);
          updates['waitingListIds'] = newWaitingList;
        } else if (event.participantIds.contains(userId)) {
          // 如果在參與者名單
          // 1. 檢查能否取消 (例如活動開始前多久不能取消)
          final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
          if (hoursUntilEvent < 4) {
            // TODO: 這裡應該結合信用點數系統扣分，目前先允許但警告?
          }

          final newParticipantIds = List<String>.from(event.participantIds)..remove(userId);
          final newParticipantStatus = Map<String, dynamic>.from(event.participantStatus)..remove(userId);

          // 2. 檢查候補遞補
          if (event.waitingListIds.isNotEmpty) {
            // 取出候補第一位
            final nextUserId = event.waitingListIds.first;
            final newWaitingList = List<String>.from(event.waitingListIds)..removeAt(0);

            // 加入參與者
            newParticipantIds.add(nextUserId);
            newParticipantStatus[nextUserId] = 'confirmed';

            updates['waitingListIds'] = newWaitingList;

            // TODO: 發送通知給 nextUserId
          }

          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // 3. 狀態更新
          // 如果原本是 confirmed，現在有人退出且沒有候補遞補，導致人數 < max，是否要變回 pending?
          // 這裡設定：如果人數少於 max - 2 (例如少於4人)，變回 pending
          if (event.status == 'confirmed' && newParticipantIds.length < (event.maxParticipants - 1)) {
             updates['status'] = 'pending';
             updates['confirmedAt'] = null;
          }

          if (newParticipantIds.isEmpty) {
            updates['status'] = 'cancelled';
          }
        } else {
          throw Exception('您未參加此活動');
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      debugPrint('Error leaving event: $e');
      rethrow;
    }
  }

  /// 獲取推薦的活動列表
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      final now = DateTime.now();
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
              event.participantIds.length < event.maxParticipants && // 只推薦有空位的
              event.dateTime.isAfter(now) &&
              !event.isRegistrationClosed
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
        await joinEvent(targetEventId, userId);
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
