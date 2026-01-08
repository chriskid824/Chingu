import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/routes/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  /// 處理通知點擊
  void handleNotificationClick(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 根據通知類型或動作類型導航
    if (notification.actionType != null && notification.actionType!.isNotEmpty) {
      _navigateByAction(navigator, notification.actionType!, notification.actionData);
    } else {
      _navigateByType(navigator, notification.type, notification.actionData);
    }
  }

  void _navigateByAction(NavigatorState navigator, String actionType, String? actionData) {
    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          // 構建一個臨時的 UserModel 以便 ChatDetailScreen 可以顯示
          // 實際應用中可能需要先從後端獲取完整的用戶資料
          // 這裡使用通知標題作為用戶名，如果有圖片URL則作為頭像
          // 注意：這是一個權宜之計，為了適配 ChatDetailScreen 對 UserModel 的依賴
          final dummyUser = UserModel(
            uid: 'unknown', // 我們不知道對方的UID，除非包含在 actionData 中
            name: 'Chat User', // 暫時使用通用名稱，理想情況下通知模型應包含 senderName
            email: '',
            age: 0,
            gender: 'other',
            job: '',
            interests: [],
            country: '',
            city: '',
            district: '',
            preferredMatchType: 'any',
            minAge: 0,
            maxAge: 100,
            budgetRange: 0,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          navigator.pushNamed(
            AppRoutes.chatDetail,
            arguments: {
              'chatRoomId': actionData,
              'otherUser': dummyUser,
            },
          );
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'open_event':
        if (actionData != null) {
           navigator.pushNamed(
            AppRoutes.eventDetail,
            arguments: actionData, // 假設 eventDetail 接受 eventId 作為參數
          );
        } else {
          navigator.pushNamed(AppRoutes.eventsList);
        }
        break;
      case 'open_match':
        if (actionData != null) {
           navigator.pushNamed(
            AppRoutes.userDetail, // 假設有用戶詳情頁
            arguments: actionData, // userId
          );
        } else {
           navigator.pushNamed(AppRoutes.matchesList);
        }
        break;
      case 'open_profile':
         navigator.pushNamed(AppRoutes.profileDetail);
        break;
      default:
        // 默認行為或不操作
        break;
    }
  }

  void _navigateByType(NavigatorState navigator, String type, String? actionData) {
    switch (type) {
      case 'message':
         navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'match':
         navigator.pushNamed(AppRoutes.matchesList);
        break;
      case 'event':
        // 如果有具體活動ID，可以導航到詳情
        if (actionData != null) {
           navigator.pushNamed(
            AppRoutes.eventDetail,
            arguments: actionData,
          );
        } else {
           navigator.pushNamed(AppRoutes.eventsList);
        }
        break;
      case 'rating':
         navigator.pushNamed(AppRoutes.eventRating);
        break;
      case 'system':
      default:
        // 系統通知可能不需要導航，或者導航到首頁
        // navigator.pushNamed(AppRoutes.home);
        break;
    }
  }
}
