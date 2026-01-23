import 'package:chingu/models/notification_model.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/notification_storage_service.dart';

class NotificationService {
  final NotificationStorageService _storageService;
  final NotificationABService _abService;

  NotificationService({
    NotificationStorageService? storageService,
    NotificationABService? abService,
  })  : _storageService = storageService ?? NotificationStorageService(),
        _abService = abService ?? NotificationABService();

  /// 發送配對通知
  ///
  /// [sender] 發送者 (配對對象)
  /// [receiver] 接收者 (通知目標)
  /// [chatRoomId] 關聯的聊天室 ID
  Future<void> sendMatchNotification(UserModel sender, UserModel receiver, String chatRoomId) async {
    // 1. 決定通知內容 (A/B Test)
    final content = _abService.getContent(
      receiver.uid,
      NotificationType.match,
      params: {'partnerName': sender.name},
    );

    // 2. 建立通知模型
    final notification = NotificationModel(
      id: '', // Firestore auto-id
      userId: receiver.uid,
      type: 'match',
      title: content.title,
      message: content.body,
      imageUrl: sender.avatarUrl,
      actionType: 'open_chat',
      actionData: chatRoomId,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 3. 儲存到 Firestore (這通常會觸發後端的 Cloud Function 發送 FCM 推播)
    await _storageService.sendNotificationToUser(receiver.uid, notification);
  }
}
