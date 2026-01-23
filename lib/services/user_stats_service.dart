import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/chat_service.dart';

class UserStatsService {
  final FirestoreService _firestoreService;
  final DinnerEventService _dinnerEventService;
  final ChatService _chatService;

  UserStatsService({
    FirestoreService? firestoreService,
    DinnerEventService? dinnerEventService,
    ChatService? chatService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _dinnerEventService = dinnerEventService ?? DinnerEventService(),
        _chatService = chatService ?? ChatService();

  /// 獲取用戶統計數據
  /// 返回包含 'matches', 'events', 'chats' 的 Map
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // 並行執行查詢以提高效能
      final results = await Future.wait([
        _getMatchCount(userId),
        _getEventCount(userId),
        _getChatCount(userId),
      ]);

      return {
        'matches': results[0],
        'events': results[1],
        'chats': results[2],
      };
    } catch (e) {
      throw Exception('獲取用戶統計失敗: $e');
    }
  }

  Future<int> _getMatchCount(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      return user?.totalMatches ?? 0;
    } catch (e) {
      print('獲取配對數失敗: $e');
      return 0;
    }
  }

  Future<int> _getEventCount(String userId) async {
    try {
      final events = await _dinnerEventService.getUserEvents(userId);
      return events.length;
    } catch (e) {
      print('獲取活動數失敗: $e');
      return 0;
    }
  }

  Future<int> _getChatCount(String userId) async {
    try {
      return await _chatService.getUserChatRoomCount(userId);
    } catch (e) {
      print('獲取聊天數失敗: $e');
      return 0;
    }
  }
}
