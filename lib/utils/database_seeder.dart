
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _random = Random();

  /// 生成並寫入測試數據
  Future<void> seedData() async {
    try {
      debugPrint('開始清理並生成測試數據...');
      await clearAllData();
      
      debugPrint('步驟 1/3: 生成用戶數據...');
      await _seedUsers();
      
      debugPrint('步驟 2/3: 生成活動數據...');
      try {
        await _seedEvents();
        debugPrint('✓ 活動數據生成完成');
      } catch (e, stackTrace) {
        debugPrint('✗ 活動數據生成失敗: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      debugPrint('步驟 3/3: 生成配對和聊天數據...');
      await _seedTestMatchesAndChats();
      
      debugPrint('測試數據生成完成！');
    } catch (e) {
      debugPrint('生成測試數據失敗: $e');
      rethrow;
    }
  }

  /// 清除所有數據
  Future<void> clearAllData() async {
    try {
      debugPrint('正在清理舊數據...');
      
      // 只刪除測試數據，保留真實用戶（有 email 的）
      // 1. 刪除沒有 email 或 email 包含 dummy 的測試用戶
      // ⚠️ 重要：絕對不刪除當前登入的用戶
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      final usersQuery = await _firestore.collection('users').get();
      for (var doc in usersQuery.docs) {
        // 如果是當前用戶，跳過
        if (doc.id == currentUserId) {
          debugPrint('跳過當前用戶: ${doc.id}');
          continue;
        }

        final data = doc.data();
        final email = data['email'] as String?;
        // 只刪除沒有 email 或 email 是虛擬的測試數據
        if (email == null || email.isEmpty || email.startsWith('dummy')) {
          await doc.reference.delete();
        }
      }
      debugPrint('已清空測試用戶（保留當前用戶）');
      
      // 2. 清空其他集合
      final collections = ['dinner_events', 'chat_rooms', 'messages'];
      
      for (var collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        debugPrint('已清空集合: $collection');
      }
      
      debugPrint('舊數據清理完成！');
    } catch (e) {
      debugPrint('清理數據失敗: $e');
      rethrow;
    }
  }


  Future<void> _seedUsers() async {
    final usersCollection = _firestore.collection('users');
    
    final List<String> maleNames = ['張阿傑', 'Michael Wang', 'David Chen', 'Kevin Lin', 'Tom Wu', 'Jason Lee', 'Eric Chang', 'Ryan Liu', 'Alex Huang', 'Daniel Tsai'];
    final List<String> femaleNames = ['艾蜜莉', 'Sarah Lin', 'Yuki', 'Jessica Chen', 'Amanda Wu', 'Kelly Yang', 'Sophie Chang', 'Tina Liu', 'Grace Huang', 'Olivia Lin'];
    final List<String> jobs = ['UI 設計師', '軟體工程師', '行銷企劃', '產品經理', '插畫家', '建築師', '教師', '會計師', '業務經理', '自由接案者'];
    final List<String> interestsPool = ['設計', '咖啡', '展覽', '攝影', '科技', '健身', '美食', '投資', '電影', '旅行', '調酒', '音樂', '創業', '閱讀', '籃球', '戶外', '繪畫', '貓咪', '甜點', '日劇'];
    
    // 預設區域
    List<String> districts = ['信義區', '大安區', '中山區', '內湖區', '大同區', '松山區', '中正區', '士林區'];
    String targetCity = '台北市';

    // 嘗試獲取當前用戶的城市資訊
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await usersCollection.doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['city'] != null && userData['city'].toString().isNotEmpty) {
            targetCity = userData['city'];
            debugPrint('✓ 將為當前用戶所在城市生成數據: $targetCity');
            
            // 如果不是台北市，使用通用的區域名稱或單一區域
            if (targetCity != '台北市') {
              districts = ['市區', '北區', '南區', '東區', '西區'];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('獲取當前用戶城市失敗，使用預設值: $e');
    }

    debugPrint('正在生成 20 個測試用戶 ($targetCity)...');

    for (int i = 0; i < 20; i++) {
      final isMale = _random.nextBool();
      final name = isMale ? maleNames[i % maleNames.length] : femaleNames[i % femaleNames.length];
      final gender = isMale ? 'male' : 'female';
      
      // 隨機興趣 (3-5個)
      final shuffledInterests = List<String>.from(interestsPool)..shuffle(_random);
      final userInterests = shuffledInterests.take(3 + _random.nextInt(3)).toList();

      final uid = _uuid.v4();
      final user = UserModel(
        uid: uid,
        email: 'test_${uid.substring(0, 5)}@example.com',
        name: '$name ${i+1}', // 加上編號避免重複
        avatarUrl: null,
        gender: gender,
        age: 22 + _random.nextInt(15), // 22-37歲
        country: 'Taiwan',
        job: jobs[_random.nextInt(jobs.length)],
        city: targetCity, // 使用目標城市
        district: districts[_random.nextInt(districts.length)],
        interests: userInterests,
        bio: '這是一個測試用戶，喜歡${userInterests[0]}和${userInterests[1]}。',
        budgetRange: _random.nextInt(4), // 0-3
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        diningPreference: 'any',
        minAge: 18,
        maxAge: 50,
      );

      await usersCollection.doc(uid).set(user.toMap());
    }
    debugPrint('已生成 20 個測試用戶。');
  }

  Future<void> _seedEvents() async {
    debugPrint('=== 開始生成活動資料 ===');
    final eventsCollection = _firestore.collection('dinner_events');
    String? targetUserId;
    
    // 1. 優先使用當前登入用戶
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      targetUserId = currentUser.uid;
      debugPrint('使用當前登入用戶 ID: $targetUserId');
    } else {
      // 2. 否則查找 test@gmail.com
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@gmail.com')
          .limit(1)
          .get();

      if (testUserQuery.docs.isNotEmpty) {
        targetUserId = testUserQuery.docs.first.id;
        debugPrint('使用 test@gmail.com 用戶 ID: $targetUserId');
      }
    }

    if (targetUserId == null) {
      debugPrint('警告：找不到目標用戶，跳過活動生成');
      return;
    }

    debugPrint('為用戶 $targetUserId 創建活動...');

    // 創建 3 個測試活動
    final events = [
      {
        'dateTime': DateTime.now().add(const Duration(days: 2, hours: 19)),
        'budgetRange': 1, // 500-800
        'city': '台北市',
        'district': '信義區',
        'notes': '週末輕鬆聚餐，歡迎新朋友！',
      },
      {
        'dateTime': DateTime.now().add(const Duration(days: 5, hours: 18, minutes: 30)),
        'budgetRange': 2, // 800-1200
        'city': '台北市',
        'district': '大安區',
        'notes': '喜歡美食的朋友一起來～',
      },
      {
        'dateTime': DateTime.now().add(const Duration(days: 7, hours: 20)),
        'budgetRange': 1,
        'city': '新北市',
        'district': '板橋區',
        'notes': '認識新朋友，分享生活趣事',
      },
    ];

    for (var eventData in events) {
      final eventId = _uuid.v4();
      final eventDateTime = eventData['dateTime'] as DateTime;
      final event = DinnerEventModel(
        id: eventId,
        eventDate: eventDateTime,
        signupDeadline: eventDateTime.subtract(const Duration(days: 1)),
        city: eventData['city'] as String,
        signedUpUsers: [targetUserId],
        status: 'open',
        createdAt: DateTime.now(),
      );

      await eventsCollection.doc(eventId).set(event.toMap());
    }
    
    debugPrint('已為測試用戶生成 ${events.length} 個活動。');
  }

  /// 為測試用戶創建配對和聊天室
  Future<void> _seedTestMatchesAndChats() async {
    try {
      debugPrint('開始為 test@gmail.com 創建測試配對...');
      
      // 調試：先列出所有用戶和他們的 email
      final allUsers = await _firestore.collection('users').get();
      debugPrint('資料庫中總共有 ${allUsers.docs.length} 個用戶：');
      for (var doc in allUsers.docs) {
        final data = doc.data();
        debugPrint('  - ID: ${doc.id}, Email: ${data['email']}, Name: ${data['name']}');
      }
      
      // 1. 查找測試用戶
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@gmail.com')
          .limit(1)
          .get();

      debugPrint('查詢 email=test@gmail.com 的結果：${testUserQuery.docs.length} 個文檔');

      if (testUserQuery.docs.isEmpty) {
        debugPrint('警告：找不到 test@gmail.com 用戶，跳過配對生成');
        debugPrint('請確認：');
        debugPrint('1. 您是否用 test@gmail.com 註冊？');
        debugPrint('2. 註冊時是否成功保存到 Firestore？');
        return;
      }

      final testUserId = testUserQuery.docs.first.id;
      debugPrint('找到測試用戶 ID: $testUserId');

      // 2. 獲取 3 個隨機測試用戶進行配對
      final allUsersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: testUserId)
          .limit(5)
          .get();

      if (allUsersQuery.docs.isEmpty) {
        debugPrint('警告：沒有其他用戶可以配對');
        return;
      }

      final matchUsers = allUsersQuery.docs.take(3).toList();
      debugPrint('選擇了 ${matchUsers.length} 個用戶進行配對');

      // 3. 為每個用戶創建雙向喜歡記錄和聊天室
      for (var i = 0; i < matchUsers.length; i++) {
        final matchUserId = matchUsers[i].id;
        final matchUserData = matchUsers[i].data();
        final matchUserName = matchUserData['name'] ?? '用戶${i + 1}';

        // 3.1 創建聊天室（模擬雙向 👍 Match 後建立）
        final chatRoomId = _uuid.v4();
        final chatRoomData = {
          'id': chatRoomId,
          'participantIds': [testUserId, matchUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': '嗨！很高興認識你 😊',
        };

        await _firestore.collection('chat_rooms').doc(chatRoomId).set(chatRoomData);
        debugPrint('✓ 創建了與 $matchUserName 的聊天室: $chatRoomId');

        // 3.3 添加測試訊息
        final messages = [
          {
            'chatRoomId': chatRoomId,
            'senderId': matchUserId,
            'text': '嗨！很高興認識你 😊',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          },
          {
            'chatRoomId': chatRoomId,
            'senderId': matchUserId,
            'text': '你好呀！有空一起吃飯嗎？',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          },
        ];

        for (var message in messages) {
          await _firestore.collection('messages').add(message);
        }

        debugPrint('✓ 添加了測試訊息');
      }

      debugPrint('成功為 test@gmail.com 創建了 ${matchUsers.length} 個配對和聊天室！');
    } catch (e) {
      debugPrint('創建測試配對失敗: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
      // 不拋出異常，允許其他數據生成繼續
    }
  }

  /// 生成餐廳種子資料（台北市信義區為主）
  Future<void> seedRestaurants() async {
    debugPrint('開始生成餐廳種子資料...');
    final collection = _firestore.collection('restaurants');

    // 先清除舊的種子餐廳
    final existing = await collection.get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    final restaurants = [
      // ── budgetLevel 0: NT$ 300-500（平價）──
      _restaurant('小巷食堂', '台北市信義區松仁路 28 號', 25.0330, 121.5654,
          '02-2720-0001', 0, ['no_beef', 'vegetarian'], '信義區'),
      _restaurant('暖心拉麵屋', '台北市信義區忠孝東路五段 15 號', 25.0410, 121.5670,
          '02-2720-0002', 0, [], '信義區'),
      _restaurant('POKE BOWL 波奇', '台北市信義區基隆路一段 155 號', 25.0380, 121.5620,
          '02-2720-0003', 0, ['no_pork', 'no_beef'], '信義區'),
      _restaurant('阿嬤的味道', '台北市信義區莊敬路 178 號', 25.0295, 121.5580,
          '02-2720-0004', 0, ['vegetarian'], '信義區'),
      _restaurant('元氣咖哩', '台北市信義區永吉路 120 號', 25.0445, 121.5710,
          '02-2720-0005', 0, [], '信義區'),

      // ── budgetLevel 1: NT$ 500-800（中價位）──
      _restaurant('山海樓台菜', '台北市信義區松壽路 12 號', 25.0360, 121.5675,
          '02-2720-0101', 1, ['no_beef'], '信義區'),
      _restaurant('初心居酒屋', '台北市信義區松德路 65 號', 25.0315, 121.5710,
          '02-2720-0102', 1, [], '信義區'),
      _restaurant('GREEN LIGHT 蔬食', '台北市信義區信義路五段 20 號', 25.0335, 121.5640,
          '02-2720-0103', 1, ['vegetarian', 'vegan'], '信義區'),
      _restaurant('泰正點', '台北市信義區松仁路 100 號', 25.0350, 121.5660,
          '02-2720-0104', 1, ['halal', 'no_pork'], '信義區'),
      _restaurant('麵道場', '台北市信義區忠孝東路四段 559 號', 25.0420, 121.5630,
          '02-2720-0105', 1, [], '信義區'),

      // ── budgetLevel 2: NT$ 800-1200（中高價位）──
      _restaurant('和牛燒肉 WAGYU+', '台北市信義區松壽路 22 號', 25.0365, 121.5680,
          '02-2720-0201', 2, [], '信義區'),
      _restaurant('義大利麵工房 Pasta Lab', '台北市信義區松高路 19 號', 25.0355, 121.5690,
          '02-2720-0202', 2, ['vegetarian'], '信義區'),
      _restaurant('鮮定味生魚片', '台北市信義區基隆路二段 39 號', 25.0300, 121.5615,
          '02-2720-0203', 2, [], '信義區'),
      _restaurant('品川懷石', '台北市信義區忠孝東路五段 68 號', 25.0415, 121.5685,
          '02-2720-0204', 2, ['no_pork'], '信義區'),
      _restaurant('The Lounge 餐酒館', '台北市信義區松智路 1 號', 25.0340, 121.5670,
          '02-2720-0205', 2, [], '信義區'),

      // ── budgetLevel 3: NT$ 1200+（高價位）──
      _restaurant('鳥苑法式料理', '台北市信義區松仁路 38 號', 25.0325, 121.5650,
          '02-2720-0301', 3, ['no_pork'], '信義區'),
      _restaurant('但馬家涮涮鍋', '台北市信義區松壽路 9 號', 25.0370, 121.5695,
          '02-2720-0302', 3, [], '信義區'),
      _restaurant('天空餐廳 SKY DINING', '台北市信義區信義路五段 7 號', 25.0332, 121.5645,
          '02-2720-0303', 3, ['vegetarian'], '信義區'),
      _restaurant('米其林壽司 OMAKASE', '台北市信義區松高路 11 號', 25.0358, 121.5688,
          '02-2720-0304', 3, [], '信義區'),
      _restaurant('頂級牛排館 PRIME', '台北市信義區松智路 17 號', 25.0345, 121.5672,
          '02-2720-0305', 3, ['halal'], '信義區'),
    ];

    for (var r in restaurants) {
      final id = _uuid.v4();
      r['id'] = id;
      await collection.doc(id).set(r);
    }

    debugPrint('✓ 已生成 ${restaurants.length} 家餐廳種子資料');
  }

  /// Helper: 建立餐廳 Map
  Map<String, dynamic> _restaurant(
    String name,
    String address,
    double lat,
    double lng,
    String phone,
    int budgetLevel,
    List<String> dietaryTags,
    String district,
  ) {
    return {
      'name': name,
      'address': address,
      'location': GeoPoint(lat, lng),
      'phone': phone,
      'imageUrl': null,
      'budgetLevel': budgetLevel,
      'maxGroupSize': 8,
      'dietaryTags': dietaryTags,
      'city': '台北市',
      'district': district,
      'isActive': true,
      'lastBookedAt': null,
      'createdAt': Timestamp.now(),
    };
  }

  /// E2E 整合測試：建立完整流程種子資料
  /// 12 用戶 → 報名同一活動 → 2 桌 dinner_groups → 各狀態覆蓋
  Future<void> seedE2EFlow() async {
    try {
      debugPrint('🚀 E2E 整合測試：開始生成完整流程資料...');

      // 清理舊的 E2E 資料
      debugPrint('清理舊的 E2E 資料...');
      final oldUsers = await _firestore.collection('users')
          .where('bio', isEqualTo: 'E2E 測試用戶').get();
      for (var doc in oldUsers.docs) {
        await doc.reference.delete();
      }
      final oldGroups = await _firestore.collection('dinner_groups').get();
      for (var doc in oldGroups.docs) {
        await doc.reference.delete();
      }
      debugPrint('✓ 舊資料清理完成');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ 請先登入');
        return;
      }
      final myUid = currentUser.uid;

      // 1. 生成 11 個測試用戶（加上自己 = 12 人 = 2 桌）
      debugPrint('步驟 1/5: 生成 11 個測試用戶...');
      final userIds = <String>[myUid]; // 自己排第一
      final interestsPool = ['設計', '咖啡', '攝影', '科技', '美食', '旅行', '音樂', '閱讀'];
      final maleNames = ['Kevin', 'Jason', 'Eric', 'Ryan', 'Alex'];
      final femaleNames = ['Sophie', 'Tina', 'Grace', 'Kelly', 'Yuki', 'Emily'];

      for (int i = 0; i < 11; i++) {
        final uid = _uuid.v4();
        final isMale = i < 5; // 5 男 6 女（加上自己的性別）
        final name = isMale ? maleNames[i % 5] : femaleNames[i % 6];
        final shuffled = List<String>.from(interestsPool)..shuffle(_random);

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': 'e2e_${uid.substring(0, 5)}@test.com',
          'name': '$name (E2E)',
          'gender': isMale ? 'male' : 'female',
          'age': 24 + _random.nextInt(10),
          'job': '測試用戶',
          'city': '台北市',
          'district': '信義區',
          'interests': shuffled.take(3 + _random.nextInt(3)).toList(),
          'budgetRange': 1,
          'bio': 'E2E 測試用戶',
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        });
        userIds.add(uid);
      }
      debugPrint('✓ 已生成 11 個測試用戶（共 12 人）');

      // 2. 建立一個已截止活動（本週四）
      debugPrint('步驟 2/5: 建立測試活動...');
      final eventId = _uuid.v4();
      final thursday = DateTime.now().add(const Duration(days: 1));
      await _firestore.collection('dinner_events').doc(eventId).set({
        'id': eventId,
        'eventDate': Timestamp.fromDate(thursday),
        'signupDeadline': Timestamp.fromDate(thursday.subtract(const Duration(hours: 24))),
        'city': '台北市',
        'signedUpUsers': userIds,
        'status': 'closed',
        'createdAt': Timestamp.now(),
      });
      debugPrint('✓ 已建立活動（12 人報名）');

      // 3. 建立 2 桌 dinner_groups（各 6 人）
      debugPrint('步驟 3/5: 建立 2 桌 dinner_groups...');

      // 桌 1: pending 狀態（自己在這桌）
      final group1Id = _uuid.v4();
      final group1Members = userIds.sublist(0, 6);
      await _firestore.collection('dinner_groups').doc(group1Id).set({
        'id': group1Id,
        'eventId': eventId,
        'memberIds': group1Members,
        'status': 'pending', // 等待揭曉
        'district': '信義區',
        'restaurantId': null,
        'restaurantName': null,
        'companionPreviews': [],
        'icebreakerQuestions': ['如果有一天不用工作，你最想做什麼？', '最近看的一部好電影？'],
        'attendanceConfirmed': {},
        'createdAt': Timestamp.now(),
      });

      // 桌 2: location_revealed 狀態
      final group2Id = _uuid.v4();
      final group2Members = userIds.sublist(6, 12);
      await _firestore.collection('dinner_groups').doc(group2Id).set({
        'id': group2Id,
        'eventId': eventId,
        'memberIds': group2Members,
        'status': 'location_revealed',
        'district': '信義區',
        'restaurantId': 'test-restaurant',
        'restaurantName': '山海樓台菜',
        'restaurantAddress': '台北市信義區松壽路 12 號',
        'companionPreviews': group2Members.map((uid) => {
          'uid': uid,
          'initial': 'T',
          'ageRange': '25-30',
          'sharedInterests': ['美食', '旅行'],
        }).toList(),
        'icebreakerQuestions': ['你的旅行清單上排第一的地方？', '最喜歡的料理類型？'],
        'attendanceConfirmed': {},
        'createdAt': Timestamp.now(),
      });
      debugPrint('✓ 桌 1: pending（你的桌）/ 桌 2: location_revealed');

      // 4. 建立 subscription（3 次免費）
      debugPrint('步驟 4/5: 建立訂閱資料...');
      await _firestore.collection('subscriptions').doc(myUid).set({
        'plan': 'free',
        'freeTrialsRemaining': 3,
        'singleTickets': 0,
      });
      debugPrint('✓ 已設定 3 次免費體驗');

      // 5. 建立餐廳資料（如果沒有）
      debugPrint('步驟 5/5: 確認餐廳資料...');
      final restaurantCount = await _firestore.collection('restaurants').count().get();
      if (restaurantCount.count == 0) {
        await seedRestaurants();
      } else {
        debugPrint('✓ 餐廳資料已存在（${restaurantCount.count} 家）');
      }

      debugPrint('\n🎉 E2E 種子資料生成完成！');
      debugPrint('┌─────────────────────────────────┐');
      debugPrint('│ 12 個用戶（5 男 + 6 女 + 你）     │');
      debugPrint('│ 1 個活動（12 人報名）              │');
      debugPrint('│ 2 桌群組（pending + revealed）    │');
      debugPrint('│ 你的訂閱（3 次免費）               │');
      debugPrint('│ 20 家餐廳                         │');
      debugPrint('└─────────────────────────────────┘');
      debugPrint('\n📱 測試路徑：');
      debugPrint('1. 首頁 → 看到「我的群組」（pending 狀態）');
      debugPrint('2. 點群組 → 看到配對說明（🧠 我們如何配對）');
      debugPrint('3. 報名新活動 → 看到費用說明 + 付費檢查');
      debugPrint('4. 互評 → 體驗回饋 BottomSheet');
    } catch (e) {
      debugPrint('❌ E2E 種子資料生成失敗: $e');
      rethrow;
    }
  }

  /// 🧪 完整測試情境種子資料（為當前登入帳號生成）
  ///
  /// 涵蓋 6 大模組 15 個 User Case：
  /// A. 活動報名  B. 群組狀態機  C. 聊天
  /// D. 評價互評  E. Events Tab  F. 訂閱額度
  Future<void> seedTestScenariosForUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ 請先登入');
        return;
      }
      final myUid = currentUser.uid;
      debugPrint('🚀 開始生成完整測試情境資料... (UID: $myUid)');

      // ── 清理舊測試資料 ──
      debugPrint('步驟 0/7: 清理舊測試資料...');
      await _cleanTestData(myUid);

      // ── 1. 生成 16 個假用戶 ──
      debugPrint('步驟 1/7: 生成 16 個假測試用戶...');
      final mockUserIds = <String>[];
      final mockNames = ['Alex', 'Sophie', 'Kevin', 'Tina', 'Ryan', 'Lisa', 'David', 'Emma', 'John', 'Alice', 'Tom', 'Chloe', 'Eric', 'Zoe', 'Leo', 'Mia'];
      final mockGenders = ['male', 'female', 'male', 'female', 'male', 'female', 'male', 'female', 'male', 'female', 'male', 'female', 'male', 'female', 'male', 'female'];
      final mockIndustries = ['Technology', 'Arts', 'Financial services', 'Healthcare', 'Services'];
      final mockNationalities = ['Taiwan', 'Taiwan', 'Japan', 'Taiwan', 'USA'];

      for (int i = 0; i < 16; i++) {
        final uid = _uuid.v4();
        mockUserIds.add(uid);
        final shuffled = ['設計', '咖啡', '攝影', '科技', '美食', '旅行', '音樂']..shuffle(_random);

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': 'testscenario_${uid.substring(0, 5)}@chingu.local',
          'name': '${mockNames[i]} (Test)',
          'gender': mockGenders[i],
          'age': 25 + _random.nextInt(8),
          'job': '測試用戶',
          'city': '台北市',
          'district': '信義區',
          'interests': shuffled.take(4).toList(),
          'budgetRange': 1,
          'bio': '測試情境用戶',
          'country': mockNationalities[i % 5],
          'avatarUrl': 'https://i.pravatar.cc/150?img=${10 + i}',
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        });
      }
      debugPrint('✓ 16 個假用戶已生成');

      // 分配 4 組不同的參與者名單 (每組包含自己 + 4位不同的人)
      final part1 = [myUid, ...mockUserIds.sublist(0, 4)];
      final part2 = [myUid, ...mockUserIds.sublist(4, 8)];
      final part3 = [myUid, ...mockUserIds.sublist(8, 12)];
      final part4 = [myUid, ...mockUserIds.sublist(12, 16)];

      // ── 2. 生成 4 個活動 ──
      debugPrint('步驟 2/7: 生成 4 個活動...');
      final now = DateTime.now();

      // 2 個已過期活動（Events Tab 歷史用）
      final pastEvent1Id = _uuid.v4();
      final pastDate1 = DateTime(now.year, now.month, now.day - 14, 19, 0);
      await _firestore.collection('dinner_events').doc(pastEvent1Id).set({
        'eventDate': Timestamp.fromDate(pastDate1),
        'signupDeadline': Timestamp.fromDate(pastDate1.subtract(const Duration(days: 1))),
        'city': '台北市',
        'signedUpUsers': part4,
        'status': 'completed',
        'createdAt': Timestamp.fromDate(pastDate1.subtract(const Duration(days: 7))),
      });

      final pastEvent2Id = _uuid.v4();
      final pastDate2 = DateTime(now.year, now.month, now.day - 7, 19, 0);
      await _firestore.collection('dinner_events').doc(pastEvent2Id).set({
        'eventDate': Timestamp.fromDate(pastDate2),
        'signupDeadline': Timestamp.fromDate(pastDate2.subtract(const Duration(days: 1))),
        'city': '台北市',
        'signedUpUsers': part3,
        'status': 'completed',
        'createdAt': Timestamp.fromDate(pastDate2.subtract(const Duration(days: 7))),
      });

      // 2 個未來活動（報名 / 上限測試用）
      final futureEvent1Id = _uuid.v4();
      final futureDate1 = DateTime(now.year, now.month, now.day + 3, 19, 0);
      await _firestore.collection('dinner_events').doc(futureEvent1Id).set({
        'eventDate': Timestamp.fromDate(futureDate1),
        'signupDeadline': Timestamp.fromDate(futureDate1.subtract(const Duration(days: 1))),
        'city': '台北市',
        'signedUpUsers': part1,
        'status': 'open',
        'createdAt': Timestamp.now(),
      });

      final futureEvent2Id = _uuid.v4();
      final futureDate2 = DateTime(now.year, now.month, now.day + 10, 19, 0);
      await _firestore.collection('dinner_events').doc(futureEvent2Id).set({
        'eventDate': Timestamp.fromDate(futureDate2),
        'signupDeadline': Timestamp.fromDate(futureDate2.subtract(const Duration(days: 1))),
        'city': '台北市',
        'signedUpUsers': part2,
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
      debugPrint('✓ 4 個活動已生成（2 已過期 + 2 未來）');

      // ── 3. 生成 4 個群組（4 種狀態各 1） ──
      debugPrint('步驟 3/7: 生成 4 個群組（各狀態）...');

      List<Map<String, dynamic>> _buildPreviews(List<String> pIds) {
        return pIds.where((id) => id != myUid).toList().asMap().entries.map((e) => {
          'index': e.key,
          'zodiac': ['♈', '♉', '♊', '♋', '♌'][e.key % 5],
          'industryCategory': mockIndustries[e.key % 5],
          'ageGroup': '25-30',
          'topInterests': ['美食', '旅行'],
          'nationality': mockNationalities[e.key % 5],
        }).toList();
      }

      // B1: pending 群組 -> 改為加入假餐廳資訊方便測試
      final group1Id = _uuid.v4();
      await _firestore.collection('dinner_groups').doc(group1Id).set({
        'eventId': futureEvent1Id,
        'participantIds': part1,
        'memberIds': part1,
        'status': 'pending',
        'reviewStatus': 'none',
        'district': '信義區',
        'restaurantId': 'test-restaurant-1',
        'restaurantName': '信義泰式料理',
        'restaurantAddress': '台北市信義區松壽路 9 號',
        'companionPreviews': _buildPreviews(part1),
        'icebreakerQuestions': ['如果有一天不用工作，你最想做什麼？'],
        'attendanceConfirmed': {},
        'createdAt': Timestamp.now(),
      });

      // B2: info_revealed 群組
      final group2Id = _uuid.v4();
      await _firestore.collection('dinner_groups').doc(group2Id).set({
        'eventId': futureEvent2Id,
        'participantIds': part2,
        'memberIds': part2,
        'status': 'info_revealed',
        'reviewStatus': 'none',
        'district': '信義區',
        'restaurantId': 'test-restaurant-3',
        'restaurantName': '松菸早午餐',
        'restaurantAddress': '台北市信義區忠孝東路四段 553 巷',
        'companionPreviews': _buildPreviews(part2),
        'icebreakerQuestions': ['最近看的一部好電影？', '你的旅行清單上排第一的地方？'],
        'attendanceConfirmed': {},
        'createdAt': Timestamp.now(),
      });

      // B3: location_revealed 群組（有餐廳 + 聊天室）
      final group3Id = _uuid.v4();
      await _firestore.collection('dinner_groups').doc(group3Id).set({
        'eventId': pastEvent2Id,
        'participantIds': part3,
        'memberIds': part3,
        'status': 'location_revealed',
        'reviewStatus': 'none',
        'district': '信義區',
        'restaurantId': 'test-restaurant',
        'restaurantName': '山海樓台菜',
        'restaurantAddress': '台北市信義區松壽路 12 號',
        'companionPreviews': _buildPreviews(part3),
        'icebreakerQuestions': ['最喜歡的料理類型？'],
        'attendanceConfirmed': {myUid: true},
        'createdAt': Timestamp.fromDate(pastDate2),
      });

      // B4: completed 群組（觸發評價）
      final group4Id = _uuid.v4();
      await _firestore.collection('dinner_groups').doc(group4Id).set({
        'eventId': pastEvent1Id,
        'participantIds': part4,
        'memberIds': part4,
        'pendingReviewees': part4.where((id) => id != myUid).toList(),
        'status': 'completed',
        'reviewStatus': 'none',
        'district': '信義區',
        'restaurantId': 'test-restaurant-2',
        'restaurantName': '韓濟蔘雞湯專門店',
        'restaurantAddress': '台北市中山區林森北路 130 號 2 樓',
        'companionPreviews': _buildPreviews(part4),
        'icebreakerQuestions': ['你最近最開心的一件事？'],
        'attendanceConfirmed': {for (var id in part4) id: true},
        'createdAt': Timestamp.fromDate(pastDate1),
      });
      debugPrint('✓ 4 個群組已生成 ( pending / info / location / completed，皆已綁定餐廳 )');

      // ── 4. 生成群組聊天室 ──
      debugPrint('步驟 4/7: 生成群組聊天室 (為 4 個群組各建 1 個)...');
      
      Future<void> _createGroupChat(String gId, List<String> pIds, String eventTitle) async {
        final chatRoomId = _uuid.v4();
        await _firestore.collection('chat_rooms').doc(chatRoomId).set({
          'participantIds': pIds,
          'type': 'group',
          'groupId': gId,
          'lastMessage': '期待 $eventTitle 的聚餐 🎉',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': {myUid: 1},
        });
        await _firestore.collection('messages').add({
          'chatRoomId': chatRoomId,
          'senderId': pIds.last,
          'text': '期待 $eventTitle 的聚餐 🎉',
          'type': 'text',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await _createGroupChat(group1Id, part1, "下次");
      await _createGroupChat(group2Id, part2, "週末");
      await _createGroupChat(group3Id, part3, "週三");
      await _createGroupChat(group4Id, part4, "上次");
      
      debugPrint('✓ 4 個群組聊天室生成完畢');

      // ── 5. 生成 1v1 Mutual Match 聊天室 ──
      debugPrint('步驟 5/7: 生成 1v1 聊天室...');
      final matchPartnerId = part4[1]; // Sophie
      final sortedIds = [myUid, matchPartnerId]..sort();
      final matchChatId = '${sortedIds[0]}_${sortedIds[1]}_$group4Id';

      await _firestore.collection('chat_rooms').doc(matchChatId).set({
        'id': matchChatId,
        'participantIds': sortedIds,
        'participants': sortedIds, // review_service 用 participants
        'groupId': group4Id,
        'eventId': pastEvent1Id,
        'matchType': 'mutual_dinner_review',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '上次聚餐很開心！有空再約 😊',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {myUid: 1, matchPartnerId: 0},
      });

      await _firestore.collection('messages').add({
        'chatRoomId': matchChatId,
        'senderId': matchPartnerId,
        'text': '嗨！很高興上次有跟你同桌 🙌',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      await _firestore.collection('messages').add({
        'chatRoomId': matchChatId,
        'senderId': matchPartnerId,
        'text': '上次聚餐很開心！有空再約 😊',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      debugPrint('✓ 1v1 Mutual Match 聊天室 + 2 則訊息已生成');

      // ── 6. 生成 reverse review（用於觸發 mutual match） ──
      debugPrint('步驟 6/7: 生成 reverse review...');
      final reverseReviewId = _uuid.v4();
      await _firestore.collection('dinner_reviews').doc(reverseReviewId).set({
        'reviewerId': part4[2], // 同團的另一個人 → 你：想再見面
        'revieweeId': myUid,
        'groupId': group4Id,
        'eventId': pastEvent1Id,
        'result': 'like',
        'createdAt': Timestamp.now(),
      });
      debugPrint('✓ Reverse review 已生成（Sophie → 你：想再見面）');

      // ── 7. 設定訂閱額度 ──
      debugPrint('步驟 7/7: 設定訂閱額度...');
      await _firestore.collection('subscriptions').doc(myUid).set({
        'plan': 'free',
        'freeTrialsRemaining': 2,
        'singleTickets': 0,
        'status': 'active',
        'freeTicketsUsed': 1,
      });
      debugPrint('✓ 訂閱額度已設定（免費剩餘 2 次）');

      // ── 完成 ──
      debugPrint('\n🎉 完整測試情境資料生成完成！');
      debugPrint('┌───────────────────────────────────────┐');
      debugPrint('│ 5 個假用戶                             │');
      debugPrint('│ 4 個活動（2 已過期 + 2 未來）           │');
      debugPrint('│ 4 個群組（pending/info/location/done） │');
      debugPrint('│ 2 個聊天室（群組 + 1v1 mutual match）  │');
      debugPrint('│ 4 則訊息（各 2 則）                     │');
      debugPrint('│ 1 筆 reverse review（觸發 mutual）     │');
      debugPrint('│ 訂閱：免費剩餘 2 次                     │');
      debugPrint('└───────────────────────────────────────┘');
    } catch (e) {
      debugPrint('❌ 測試情境資料生成失敗: $e');
      rethrow;
    }
  }

  /// 清理測試情境資料 — 無條件刪除所有跟自己相關的測試資料
  Future<void> _cleanTestData(String myUid) async {
    debugPrint('  🧹 開始強力清理...');
    
    // 1. 刪除所有測試假用戶（bio = '測試情境用戶'）
    final mockUsers = await _firestore.collection('users')
        .where('bio', isEqualTo: '測試情境用戶')
        .get();
    for (var doc in mockUsers.docs) {
      await doc.reference.delete();
    }
    debugPrint('  ✓ 刪除了 ${mockUsers.docs.length} 個假用戶');

    // 2. 刪除所有包含自己的 dinner_groups（不做任何條件判斷）
    final groups = await _firestore.collection('dinner_groups')
        .where('participantIds', arrayContains: myUid)
        .get();
    for (var doc in groups.docs) {
      await doc.reference.delete();
    }
    debugPrint('  ✓ 刪除了 ${groups.docs.length} 個群組');

    // 3. 刪除所有包含自己的 dinner_events
    final events = await _firestore.collection('dinner_events')
        .where('signedUpUsers', arrayContains: myUid)
        .get();
    for (var doc in events.docs) {
      await doc.reference.delete();
    }
    debugPrint('  ✓ 刪除了 ${events.docs.length} 個活動');

    // 4. 刪除所有包含自己的 chat_rooms 和其中的 messages
    final chats = await _firestore.collection('chat_rooms')
        .where('participantIds', arrayContains: myUid)
        .get();
    int msgCount = 0;
    for (var doc in chats.docs) {
      // 先刪除該聊天室的所有訊息
      final msgs = await _firestore.collection('messages')
          .where('chatRoomId', isEqualTo: doc.id)
          .get();
      for (var mDoc in msgs.docs) {
        await mDoc.reference.delete();
        msgCount++;
      }
      await doc.reference.delete();
    }
    debugPrint('  ✓ 刪除了 ${chats.docs.length} 個聊天室 + $msgCount 則訊息');

    // 5. 刪除所有 reviewer 或 reviewee 是自己的評價
    final reviewsAsReviewer = await _firestore.collection('dinner_reviews')
        .where('reviewerId', isEqualTo: myUid)
        .get();
    for (var doc in reviewsAsReviewer.docs) {
      await doc.reference.delete();
    }
    final reviewsAsReviewee = await _firestore.collection('dinner_reviews')
        .where('revieweeId', isEqualTo: myUid)
        .get();
    for (var doc in reviewsAsReviewee.docs) {
      await doc.reference.delete();
    }
    debugPrint('  ✓ 刪除了 ${reviewsAsReviewer.docs.length + reviewsAsReviewee.docs.length} 筆評價');
    
    debugPrint('  🧹 強力清理完畢！');
  }
}

