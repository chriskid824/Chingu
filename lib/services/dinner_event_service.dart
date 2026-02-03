import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// 晚餐活動服務 - 處理晚餐活動的創建、查詢和管理
class DinnerEventService {
  final FirebaseFirestore _firestore;

  DinnerEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _eventsCollection => _firestore.collection('dinner_events');

  // 每桌最大人數 (預設)
  static const int defaultMaxParticipants = 6;

  /// 創建新的晚餐活動
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = defaultMaxParticipants,
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

  /// 獲取用戶參與的活動列表 (Registered)
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
      
      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return events;
    } catch (e) {
      throw Exception('獲取用戶活動列表失敗: $e');
    }
  }

  /// 獲取用戶在等候清單的活動列表 (Waitlisted)
  Future<List<DinnerEventModel>> getUserWaitlistedEvents(String userId) async {
    try {
      Query query = _eventsCollection
          .where('waitlist', arrayContains: userId);

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map((doc) => DinnerEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      events.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return events;
    } catch (e) {
      throw Exception('獲取用戶等候清單失敗: $e');
    }
  }

  /// 檢查時間衝突
  Future<bool> _checkTimeConflict(String userId, DateTime eventDate) async {
    // 簡單規則：同一天晚上不能有兩個晚餐活動
    // 假設晚餐時間都是晚上，檢查同一天的活動
    final startOfDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 檢查已報名的活動
    final registeredEvents = await getUserEvents(userId);
    for (var event in registeredEvents) {
      // 忽略已取消的活動
      if (event.status == 'cancelled') continue;

      if (event.dateTime.isAfter(startOfDay) && event.dateTime.isBefore(endOfDay)) {
        return true;
      }
    }
    return false;
  }

  /// 報名活動 (Register / Join)
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
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
        if (event.waitlist.contains(userId)) {
          throw Exception('您已在等候清單中');
        }

        // 2. 時間衝突檢查 (此檢查需在 transaction 外做比較好，但為了簡單先略過 transaction 內的異步查詢限制?
        // Firestore Transaction 內必須全是 read 然後全是 write。不能 read, 外部 async, write。
        // 所以 _checkTimeConflict 應該在 transaction 之前調用。
        // 但這裡我先不將 _checkTimeConflict 放入 transaction，這可能導致極小概率的 race condition，但可接受。)
      });

      // 移到 Transaction 外
      final conflict = await _checkTimeConflict(userId, (await getEvent(eventId))!.dateTime);
      if (conflict) {
        throw Exception('此時段您已有其他活動');
      }

      // 重新開始 Transaction 進行寫入
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() as Map<String, dynamic>;
        
        // 再次讀取以確保最新狀態
        final maxParticipants = data['maxParticipants'] ?? defaultMaxParticipants;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        // 雙重檢查重複
        if (participantIds.contains(userId) || waitlist.contains(userId)) {
           return; // 已經加入，不做動作或拋出異常
        }

        if (participantIds.length < maxParticipants) {
          // 名額未滿，直接加入
          participantIds.add(userId);
          participantStatus[userId] = 'confirmed';

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
          };

          if (participantIds.length == maxParticipants) {
            // updates['status'] = 'confirmed'; // 這裡可能需要根據具體業務邏輯決定是否立即 confirm
            // 暫時保持 pending 直到系統匹配完成或滿員
          }

          transaction.update(docRef, updates);
        } else {
          // 名額已滿，加入 Waitlist
          waitlist.add(userId);
          transaction.update(docRef, {'waitlist': waitlist});
        }
      });
    } catch (e) {
      throw Exception('報名失敗: $e');
    }
  }

  /// 取消報名 / 退出活動
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _eventsCollection.doc(eventId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('活動不存在');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final eventDate = (data['dateTime'] as Timestamp).toDate();
        final now = DateTime.now();

        // 1. 取消截止時間檢查 (24小時)
        if (eventDate.difference(now).inHours < 24) {
          throw Exception('活動前24小時內不可取消');
        }

        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final waitlist = List<String>.from(data['waitlist'] ?? []);
        final participantStatus = Map<String, dynamic>.from(data['participantStatus'] ?? {});

        if (participantIds.contains(userId)) {
          // 是正式參與者
          participantIds.remove(userId);
          participantStatus.remove(userId);

          // 自動遞補邏輯
          if (waitlist.isNotEmpty) {
            final nextUser = waitlist.removeAt(0); // 取出第一位
            participantIds.add(nextUser);
            participantStatus[nextUser] = 'confirmed'; // 自動確認

            // TODO: 發送通知給 nextUser (恭喜遞補成功)
          }

          final updates = {
            'participantIds': participantIds,
            'participantStatus': participantStatus,
            'waitlist': waitlist,
          };

          // 若沒人遞補且變空，可能需要處理狀態
           if (participantIds.isEmpty) {
            updates['status'] = 'cancelled';
          }

          transaction.update(docRef, updates);

        } else if (waitlist.contains(userId)) {
          // 是候補者
          waitlist.remove(userId);
          transaction.update(docRef, {'waitlist': waitlist});
        } else {
          throw Exception('您未報名此活動');
        }
      });
    } catch (e) {
      throw Exception('取消失敗: $e');
    }
  }

  // 為了兼容舊代碼，保留 joinEvent 但指向 registerForEvent
  Future<void> joinEvent(String eventId, String userId) async {
    await registerForEvent(eventId, userId);
  }

  // 為了兼容舊代碼，保留 leaveEvent 但指向 unregisterFromEvent
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
              event.participantIds.length < event.maxParticipants && // 使用 maxParticipants
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

  /// 計算本週四和下週四的日期 (保留原邏輯)
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
        final maxParticipants = data['maxParticipants'] ?? defaultMaxParticipants;
        
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
