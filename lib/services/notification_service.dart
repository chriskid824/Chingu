import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:flutter/foundation.dart';

/// 負責處理通知發送邏輯的服務
/// 整合了 Cloud Functions (發送給他人) 和 NotificationStorageService (本地/自己)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // 依賴注入 (用於測試)
  FirebaseFunctions? _functions;
  NotificationStorageService? _storageService;

  FirebaseFunctions get _cloudFunctions =>
      _functions ?? FirebaseFunctions.instance;

  NotificationStorageService get _notificationStorage =>
      _storageService ?? NotificationStorageService();

  @visibleForTesting
  void setDependencies({
    FirebaseFunctions? functions,
    NotificationStorageService? storageService,
  }) {
    _functions = functions;
    _storageService = storageService;
  }

  /// 發送配對通知給雙方
  ///
  /// [currentUserId]: 觸發配對的當前用戶 ID
  /// [matchedUserId]: 配對對象的用戶 ID
  /// [matchedUserName]: 配對對象的名稱 (用於生成當前用戶的通知)
  /// [matchedUserPhotoUrl]: 配對對象的照片 (可選)
  Future<void> sendMatchNotification({
    required String currentUserId,
    required String matchedUserId,
    required String matchedUserName,
    String? matchedUserPhotoUrl,
  }) async {
    try {
      // 1. 發送通知給對方 (User B)
      // 調用 Cloud Function 'notifyMatch'
      // Cloud Function 會負責寫入對方的 notifications 集合，並觸發推送通知
      final callable = _cloudFunctions.httpsCallable('notifyMatch');
      await callable.call({
        'matchedUserId': matchedUserId,
      });
      debugPrint('NotificationService: Sent match notification to partner $matchedUserId');

      // 2. 為自己創建通知 (User A)
      // 使用 NotificationStorageService 直接寫入 Firestore
      // 這也會觸發 'onNotificationCreate' Cloud Function，從而發送推送給自己
      await _notificationStorage.createMatchNotification(
        matchedUserName: matchedUserName,
        matchedUserId: matchedUserId,
        matchedUserPhotoUrl: matchedUserPhotoUrl,
      );
      debugPrint('NotificationService: Created match notification for self');

    } catch (e) {
      debugPrint('NotificationService: Error sending match notification: $e');
      // 不拋出異常，以免中斷配對流程
    }
  }
}
