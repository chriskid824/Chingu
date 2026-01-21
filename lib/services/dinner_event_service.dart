import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';

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

      // 截止時間設為活動前 24 小時
      final registrationDeadline = dateTime.subtract(const Duration(hours: 24));

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
        waitingList: [],
        registrationDeadline: registrationDeadline,
        status: EventStatus.pending,
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
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    try {
      // 1. 查詢作為參與者的活動
      Query queryParticipant = _eventsCollection
          .where('participantIds', arrayContains: userId);

      if (status != null) {
        queryParticipant = queryParticipant.where('status', isEqualTo: status.name);
      }

      final snapshotParticipant = await queryParticipant.get();

      // 2. 查詢作為候補的活動 (如果需要，目前 UI 主要顯示參與的)
      // Firestore 不支持 logical OR on different fields easily in one query
      // 這裡先只返回參與的活動

      final events = snapshotParticipant.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 加入活動 (正式參與)
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        if (event.participantIds.contains(userId)) {
          throw Exception('您已加入此活動');
        }

        if (event.isRegistrationClosed) {
          throw Exception('報名已截止');
        }

        if (event.isFull) {
          throw Exception('活動人數已滿，請加入候補名單');
        }

        // 如果在候補名單中，先移除
        List<String> newWaitingList = List.from(event.waitingList);
        if (newWaitingList.contains(userId)) {
          newWaitingList.remove(userId);
        }

        // 更新參與者列表
        List<String> newParticipantIds = List.from(event.participantIds)..add(userId);
        Map<String, String> newParticipantStatus = Map.from(event.participantStatus);
        newParticipantStatus[userId] = 'confirmed';

        final updates = {
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
          'waitingList': newWaitingList,
        };

        // 如果人數達到 6 人，自動確認活動
        if (newParticipantIds.length == MAX_PARTICIPANTS) {
          updates['status'] = EventStatus.confirmed.name;
          updates['confirmedAt'] = FieldValue.serverTimestamp();
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('加入活動失敗: $e');
    }
  }

  /// 加入候補名單
  Future<void> joinWaitlist(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);

        if (event.participantIds.contains(userId)) throw Exception('您已是參與者');
        if (event.waitingList.contains(userId)) throw Exception('您已在候補名單中');
        if (event.isRegistrationClosed) throw Exception('報名已截止');

        List<String> newWaitingList = List.from(event.waitingList)..add(userId);
        transaction.update(docRef, {'waitingList': newWaitingList});
      });
    } catch (e) {
      throw Exception('加入候補失敗: $e');
    }
  }

  /// 退出候補名單
  Future<void> leaveWaitlist(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        if (!event.waitingList.contains(userId)) throw Exception('您不在候補名單中');

        List<String> newWaitingList = List.from(event.waitingList)..remove(userId);
        transaction.update(docRef, {'waitingList': newWaitingList});
      });
    } catch (e) {
      throw Exception('退出候補失敗: $e');
    }
  }

  /// 退出活動
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('活動不存在');

        final event = DinnerEventModel.fromMap(snapshot.data() as Map<String, dynamic>, eventId);
        
        if (!event.participantIds.contains(userId)) {
           // 如果在候補名單，嘗試退出候補
           if (event.waitingList.contains(userId)) {
             List<String> newWaitingList = List.from(event.waitingList)..remove(userId);
             transaction.update(docRef, {'waitingList': newWaitingList});
             return;
           }
           throw Exception('您未加入此活動');
        }

        if (event.isRegistrationClosed) {
          // TODO: 實現懲罰邏輯 (Module 2)
          // throw Exception('報名截止後取消將扣除信用點數');
        }

        // 移除參與者
        List<String> newParticipantIds = List.from(event.participantIds)..remove(userId);
        Map<String, String> newParticipantStatus = Map.from(event.participantStatus);
        newParticipantStatus.remove(userId);
        List<String> newWaitingList = List.from(event.waitingList);

        final updates = <String, dynamic>{
          'participantIds': newParticipantIds,
          'participantStatus': newParticipantStatus,
        };

        // 候補名單晉升邏輯
        if (newWaitingList.isNotEmpty) {
          String promotedUserId = newWaitingList.removeAt(0);
          newParticipantIds.add(promotedUserId);
          newParticipantStatus[promotedUserId] = 'confirmed';
          updates['waitingList'] = newWaitingList;
          updates['participantIds'] = newParticipantIds;
          updates['participantStatus'] = newParticipantStatus;

          // TODO: 通知被晉升的用戶
        }

        // 狀態更新
        // 如果原本是 confirmed 且現在人數 < 6 (且沒有候補補上)，變回 pending
        if (event.status == EventStatus.confirmed && newParticipantIds.length < MAX_PARTICIPANTS) {
          updates['status'] = EventStatus.pending.name;
        }

        // 如果沒有參與者了，取消活動
        if (newParticipantIds.isEmpty) {
          updates['status'] = EventStatus.cancelled.name;
        }

        transaction.update(docRef, updates);
      });
    } catch (e) {
      throw Exception('退出活動失敗: $e');
    }
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
          .where('status', isEqualTo: EventStatus.pending.name)
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
          .where('status', isEqualTo: EventStatus.pending.name)
          .get();
          
      String? targetEventId;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['district'] != district) continue;
        
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        if (eventDate.isBefore(startOfDay) || eventDate.isAfter(endOfDay)) continue;
        
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (participantIds.contains(userId)) {
          return doc.id;
        }
        
        if (participantIds.length < MAX_PARTICIPANTS) {
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
