import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_storage_service.dart';

/// 通知服務 - 負責處理業務邏輯並協調 NotificationStorageService
class NotificationService {
  final FirestoreService _firestoreService;
  final NotificationStorageService _storageService;

  NotificationService({
    FirestoreService? firestoreService,
    NotificationStorageService? storageService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? NotificationStorageService();

  /// 發送配對通知給雙方
  Future<void> sendMatchNotification(String user1Id, String user2Id) async {
    try {
      // 獲取雙方資料
      final user1 = await _firestoreService.getUser(user1Id);
      final user2 = await _firestoreService.getUser(user2Id);

      if (user1 == null || user2 == null) {
        throw Exception('無法獲取配對用戶資料');
      }

      // 發送給 User 1 (顯示 User 2 的資訊)
      // 暫時移除 newMatchNotification 檢查，因為 UserModel 尚未定義該欄位
      await _storageService.createMatchNotification(
        matchedUserName: user2.name,
        matchedUserId: user2.uid,
        matchedUserPhotoUrl: user2.avatarUrl,
        receiverId: user1Id,
      );

      // 發送給 User 2 (顯示 User 1 的資訊)
      await _storageService.createMatchNotification(
        matchedUserName: user1.name,
        matchedUserId: user1.uid,
        matchedUserPhotoUrl: user1.avatarUrl,
        receiverId: user2Id,
      );

      // Note: 實際的推送通知 (Push Notification) 應由後端 Cloud Functions 監聽通知創建事件後發送
      // 或者在此處調用 Cloud Function (如果實現了 HTTP Callable Function)
    } catch (e) {
      print('發送配對通知失敗: $e');
      // 不拋出異常，以免影響配對流程
    }
  }
}
