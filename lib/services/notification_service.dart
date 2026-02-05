import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';

/// 通知服務 - 負責 FCM 初始化、Token 管理與基礎通知設置
class NotificationService {
  // 單例模式
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// 初始化通知服務
  ///
  /// 檢查權限狀態，如果已授權則獲取並註冊 Token，設置 Token 刷新監聽
  /// 注意：此方法不會主動請求權限，避免打擾用戶
  /// [userId] 當前登入的用戶 ID，用於關聯 Token
  Future<void> init(String userId) async {
    try {
      // 檢查當前權限狀態，而不是請求權限
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();

      debugPrint('NotificationService 初始化 - 用戶授權狀態: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // 獲取 FCM Token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _updateToken(userId, token);
        }

        // 監聽 Token 刷新 (避免重複監聽)
        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token Refreshed: $newToken');
          _updateToken(userId, newToken);
        });
      }
    } catch (e) {
      debugPrint('NotificationService 初始化失敗: $e');
    }
  }

  /// 更新 Firestore 中的 Token
  Future<void> _updateToken(String userId, String token) async {
    try {
      await _firestoreService.updateUser(userId, {
        'fcmToken': token,
        'lastTokenUpdate': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      });
      debugPrint('FCM Token 已更新至 Firestore');
    } catch (e) {
      debugPrint('更新 FCM Token 失敗: $e');
    }
  }

  /// 獲取當前 Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 清除 Token (例如登出時)
  Future<void> deleteToken() async {
    try {
      // 取消監聽
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('刪除 Token 失敗: $e');
    }
  }

  /// 請求權限 (公開方法，供 UI 調用)
  Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('請求通知權限失敗: $e');
      return false;
    }
  }
}
