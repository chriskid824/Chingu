
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
      print('開始清理並生成測試數據...');
      await clearAllData();
      
      print('步驟 1/3: 生成用戶數據...');
      await _seedUsers();
      
      print('步驟 2/3: 生成活動數據...');
      try {
        await _seedEvents();
        print('✓ 活動數據生成完成');
      } catch (e, stackTrace) {
        print('✗ 活動數據生成失敗: $e');
        print('Stack trace: $stackTrace');
      }
      
      print('步驟 3/3: 生成配對和聊天數據...');
      await _seedTestMatchesAndChats();
      
      print('測試數據生成完成！');
    } catch (e) {
      print('生成測試數據失敗: $e');
      rethrow;
    }
  }

  /// 清除所有數據
  Future<void> clearAllData() async {
    try {
      print('正在清理舊數據...');
      
      // 只刪除測試數據，保留真實用戶（有 email 的）
      // 1. 刪除沒有 email 或 email 包含 dummy 的測試用戶
      // ⚠️ 重要：絕對不刪除當前登入的用戶
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      final usersQuery = await _firestore.collection('users').get();
      for (var doc in usersQuery.docs) {
        // 如果是當前用戶，跳過
        if (doc.id == currentUserId) {
          print('跳過當前用戶: ${doc.id}');
          continue;
        }

        final data = doc.data();
        final email = data['email'] as String?;
        // 只刪除沒有 email 或 email 是虛擬的測試數據
        if (email == null || email.isEmpty || email.startsWith('dummy')) {
          await doc.reference.delete();
        }
      }
      print('已清空測試用戶（保留當前用戶）');
      
      // 2. 清空其他集合
      final collections = ['dinner_events', 'swipes', 'chat_rooms', 'messages'];
      
      for (var collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        print('已清空集合: $collection');
      }
      
      print('舊數據清理完成！');
    } catch (e) {
      print('清理數據失敗: $e');
      rethrow;
    }
  }

  /// 生成互相喜歡的測試數據（用於測試配對成功流程）
  /// 這會創建一些已經喜歡 test@gmail.com 的用戶
  /// 當 test@gmail.com 喜歡他們時，就會觸發配對成功
  Future<void> seedMutualLikes() async {
    try {
      print('開始生成互相喜歡的測試數據...');
      
      // 1. 查找測試用戶
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@gmail.com')
          .limit(1)
          .get();

      if (testUserQuery.docs.isEmpty) {
        print('❌ 找不到 test@gmail.com 用戶');
        print('請確認您已經用 test@gmail.com 登入並完成個人資料設定');
        return;
      }

      final testUserId = testUserQuery.docs.first.id;
      final testUserData = testUserQuery.docs.first.data();
      print('✓ 找到測試用戶: ${testUserData['name']} ($testUserId)');

      // 2. 獲取其他用戶（排除測試用戶和已經滑過的）
      final allUsersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: testUserId)
          .limit(10)
          .get();

      if (allUsersQuery.docs.isEmpty) {
        print('❌ 沒有其他用戶可以配對');
        print('請先運行 Seeder 生成測試用戶');
        return;
      }

      // 3. 選擇 3 個用戶來喜歡測試用戶（但測試用戶還沒喜歡他們）
      final candidateUsers = allUsersQuery.docs.take(3).toList();
      print('\n準備創建 ${candidateUsers.length} 個單向喜歡記錄：');

      for (var i = 0; i < candidateUsers.length; i++) {
        final candidateId = candidateUsers[i].id;
        final candidateData = candidateUsers[i].data() as Map<String, dynamic>;
        final candidateName = candidateData['name'] ?? '用戶${i + 1}';

        // 創建單向 swipe 記錄：對方喜歡測試用戶
        await _firestore.collection('swipes').add({
          'userId': candidateId,
          'targetUserId': testUserId,
          'isLike': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('  ${i + 1}. $candidateName (ID: ${candidateId.substring(0, 8)}...) 已喜歡你');
      }

      print('\n✅ 成功生成測試數據！');
      print('\n📱 測試步驟：');
      print('1. 進入配對頁面（Matching Screen）');
      print('2. 找到以上用戶並滑動喜歡（或點擊愛心按鈕）');
      print('3. 應該立即彈出 "It\'s a Match!" 慶祝畫面');
      print('4. 並自動創建聊天室\n');
    } catch (e, stackTrace) {
      print('❌ 生成測試數據失敗: $e');
      print('Stack trace: $stackTrace');
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
            print('✓ 將為當前用戶所在城市生成數據: $targetCity');
            
            // 如果不是台北市，使用通用的區域名稱或單一區域
            if (targetCity != '台北市') {
              districts = ['市區', '北區', '南區', '東區', '西區'];
            }
          }
        }
      }
    } catch (e) {
      print('獲取當前用戶城市失敗，使用預設值: $e');
    }

    print('正在生成 20 個測試用戶 ($targetCity)...');

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
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 50,
      );

      await usersCollection.doc(uid).set(user.toMap());
    }
    print('已生成 20 個測試用戶。');
  }

  Future<void> _seedEvents() async {
    print('=== 開始生成活動資料 ===');
    final eventsCollection = _firestore.collection('dinner_events');
    String? targetUserId;
    
    // 1. 優先使用當前登入用戶
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      targetUserId = currentUser.uid;
      print('使用當前登入用戶 ID: $targetUserId');
    } else {
      // 2. 否則查找 test@gmail.com
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@gmail.com')
          .limit(1)
          .get();

      if (testUserQuery.docs.isNotEmpty) {
        targetUserId = testUserQuery.docs.first.id;
        print('使用 test@gmail.com 用戶 ID: $targetUserId');
      }
    }

    if (targetUserId == null) {
      print('警告：找不到目標用戶，跳過活動生成');
      return;
    }

    print('為用戶 $targetUserId 創建活動...');

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
      final event = DinnerEventModel(
        id: eventId,
        creatorId: targetUserId,
        dateTime: eventData['dateTime'] as DateTime,
        budgetRange: eventData['budgetRange'] as int,
        city: eventData['city'] as String,
        district: eventData['district'] as String,
        notes: eventData['notes'] as String,
        participantIds: [targetUserId],
        participantStatus: {targetUserId: 'confirmed'},
        status: EventStatus.pending,
        createdAt: DateTime.now(),
        icebreakerQuestions: ['大家最近有什麼有趣的事情分享嗎？'],
      );

      await eventsCollection.doc(eventId).set(event.toMap());
    }
    
    print('已為測試用戶生成 ${events.length} 個活動。');
  }

  /// 為測試用戶創建配對和聊天室
  Future<void> _seedTestMatchesAndChats() async {
    try {
      print('開始為 test@gmail.com 創建測試配對...');
      
      // 調試：先列出所有用戶和他們的 email
      final allUsers = await _firestore.collection('users').get();
      print('資料庫中總共有 ${allUsers.docs.length} 個用戶：');
      for (var doc in allUsers.docs) {
        final data = doc.data();
        print('  - ID: ${doc.id}, Email: ${data['email']}, Name: ${data['name']}');
      }
      
      // 1. 查找測試用戶
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@gmail.com')
          .limit(1)
          .get();

      print('查詢 email=test@gmail.com 的結果：${testUserQuery.docs.length} 個文檔');

      if (testUserQuery.docs.isEmpty) {
        print('警告：找不到 test@gmail.com 用戶，跳過配對生成');
        print('請確認：');
        print('1. 您是否用 test@gmail.com 註冊？');
        print('2. 註冊時是否成功保存到 Firestore？');
        return;
      }

      final testUserId = testUserQuery.docs.first.id;
      print('找到測試用戶 ID: $testUserId');

      // 2. 獲取 3 個隨機測試用戶進行配對
      final allUsersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: testUserId)
          .limit(5)
          .get();

      if (allUsersQuery.docs.isEmpty) {
        print('警告：沒有其他用戶可以配對');
        return;
      }

      final matchUsers = allUsersQuery.docs.take(3).toList();
      print('選擇了 ${matchUsers.length} 個用戶進行配對');

      // 3. 為每個用戶創建雙向喜歡記錄和聊天室
      for (var i = 0; i < matchUsers.length; i++) {
        final matchUserId = matchUsers[i].id;
        final matchUserData = matchUsers[i].data() as Map<String, dynamic>;
        final matchUserName = matchUserData['name'] ?? '用戶${i + 1}';

        // 3.1 創建雙向 swipe 記錄
        await _firestore.collection('swipes').add({
          'userId': testUserId,
          'targetUserId': matchUserId,
          'isLike': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('swipes').add({
          'userId': matchUserId,
          'targetUserId': testUserId,
          'isLike': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('✓ 創建了與 $matchUserName 的配對記錄');

        // 3.2 創建聊天室
        final chatRoomId = _uuid.v4();
        final chatRoomData = {
          'id': chatRoomId,
          'participantIds': [testUserId, matchUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': '嗨！很高興認識你 😊',
        };

        await _firestore.collection('chat_rooms').doc(chatRoomId).set(chatRoomData);
        print('✓ 創建了與 $matchUserName 的聊天室: $chatRoomId');

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

        print('✓ 添加了測試訊息');
      }

      print('成功為 test@gmail.com 創建了 ${matchUsers.length} 個配對和聊天室！');
    } catch (e) {
      print('創建測試配對失敗: $e');
      print('錯誤堆疊: ${StackTrace.current}');
      // 不拋出異常，允許其他數據生成繼續
    }
  }
}

