import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 假資料常數
  final List<String> _firstNames = ['王', '李', '陳', '林', '張', '劉', '郭', '蔡', '楊', '許'];
  final List<String> _names = ['小明', '大谷', '建民', '傑克', '阿信', '美玲', '雅婷', '怡君', '志明', '春嬌'];
  final List<String> _cities = ['台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市'];
  final List<String> _industries = ['資訊軟體', '金融業', '行銷公關', '醫療保健', '教育', '設計藝術'];
  final List<String> _avatarUrls = [
    'https://i.pravatar.cc/150?img=11',
    'https://i.pravatar.cc/150?img=12',
    'https://i.pravatar.cc/150?img=23',
    'https://i.pravatar.cc/150?img=33',
    'https://i.pravatar.cc/150?img=47',
    'https://i.pravatar.cc/150?img=68',
  ];

  /// 生成假用戶
  Future<List<String>> generateMockUsers({int count = 10}) async {
    final batch = _firestore.batch();
    final random = Random();
    List<String> userIds = [];

    for (int i = 0; i < count; i++) {
      final String uid = 'mock_user_${DateTime.now().millisecondsSinceEpoch}_$i';
      userIds.add(uid);
      
      final String name = '${_firstNames[random.nextInt(_firstNames.length)]}${_names[random.nextInt(_names.length)]}';
      
      batch.set(_firestore.collection('users').doc(uid), {
        'email': 'mock$i@chingu.local',
        'name': name,
        'gender': random.nextBool() ? 'male' : 'female',
        'city': _cities[random.nextInt(_cities.length)],
        'industry': _industries[random.nextInt(_industries.length)],
        'avatarUrl': _avatarUrls[random.nextInt(_avatarUrls.length)],
        'bio': '這是一位由 Seeder 自動產生的測試用戶。喜歡美食和旅遊。',
        'birthDate': Timestamp.fromDate(DateTime(1990 + random.nextInt(10), random.nextInt(12) + 1, random.nextInt(28) + 1)),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // 給予假用戶一個訂閱記錄
      batch.set(_firestore.collection('subscriptions').doc(uid), {
        'status': 'active',
        'freeTrialsRemaining': 3,
        'freeTicketsUsed': 0,
      });
    }

    await batch.commit();
    return userIds;
  }

  /// 產生包含當前用戶與隨機假用戶的飯局
  Future<void> generateDinnerEvents(String currentUserId, List<String> mockUserIds) async {
    final batch = _firestore.batch();
    final random = Random();
    
    // 取本週四為基準
    DateTime now = DateTime.now();
    int daysUntilThursday = DateTime.thursday - now.weekday;
    if (daysUntilThursday < 0) daysUntilThursday += 7;
    DateTime nextThursday = DateTime(now.year, now.month, now.day + daysUntilThursday, 19, 0);

    // 產生 3 場活動
    for (int i = 0; i < 3; i++) {
      // 每場塞入 3~5 個假用戶
      final numParticipants = 3 + random.nextInt(3); 
      List<String> participants = [currentUserId];
      
      mockUserIds.shuffle();
      participants.addAll(mockUserIds.take(numParticipants - 1));

      final eventRef = _firestore.collection('dinner_events').doc();
      batch.set(eventRef, {
        'eventDate': Timestamp.fromDate(nextThursday.add(Duration(days: i * 7))), // 本週四、下週四...
        'city': '台北市',
        'district': '信義區',
        'status': numParticipants >= 6 ? 'full' : 'open',
        'participantIds': participants,
        'currentParticipants': participants.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // 同時為這場飯局建立一個對應的群組 (dinner_groups)
      final groupRef = _firestore.collection('dinner_groups').doc();
      batch.set(groupRef, {
        'eventId': eventRef.id,
        'eventDate': Timestamp.fromDate(nextThursday.add(Duration(days: i * 7))),
        'participantIds': participants,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 為這場飯局建立一個聊天室對應 (讓目前的 UI 可以撈出標題)
      // 注意：目前聊天列表依賴 chat_rooms
      final chatRef = _firestore.collection('chat_rooms').doc();
      batch.set(chatRef, {
        'participantIds': participants,
        'type': 'group',
        'groupId': groupRef.id,
        'lastMessage': '期待這週的晚餐！',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// 一鍵清除所有 Seeder 產生的資料 (包含當前用戶的所有飯局)
  Future<void> clearDummyData(String currentUserId) async {
    // 注意：這在模擬器上安全，但在 Production 若未加上限制可能會誤刪
    final batch = _firestore.batch();
    
    final mockUsers = await _firestore.collection('users')
        .where('email', isGreaterThanOrEqualTo: 'mock')
        .where('email', isLessThan: 'mocm')
        .get();
    for (var doc in mockUsers.docs) { batch.delete(doc.reference); }

    final events = await _firestore.collection('dinner_events')
        .where('participantIds', arrayContains: currentUserId)
        .get();
    for (var doc in events.docs) { batch.delete(doc.reference); }
    
    final groups = await _firestore.collection('dinner_groups')
        .where('participantIds', arrayContains: currentUserId)
        .get();
    for (var doc in groups.docs) { batch.delete(doc.reference); }

    final chats = await _firestore.collection('chat_rooms')
        .where('participantIds', arrayContains: currentUserId)
        .get();
    for (var doc in chats.docs) { batch.delete(doc.reference); }
    
    if (batch.toString() != 'Batch size: 0') {
      await batch.commit();
    }
  }
}
