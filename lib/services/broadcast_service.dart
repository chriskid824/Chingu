import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for calling Cloud Functions to send broadcast notifications
/// Admin-only feature
class BroadcastService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a broadcast notification to all users
  /// 
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [imageUrl] - Optional image URL
  /// [customData] - Optional custom data payload
  Future<BroadcastResult> sendToAllUsers({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendBroadcast').call({
        'title': title,
        'body': body,
        'targetAll': true,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (customData != null) 'data': customData,
      });

      return BroadcastResult.fromJson(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send notification to users in specific cities
  Future<BroadcastResult> sendToCities({
    required String title,
    required String body,
    required List<String> cities,
    String? imageUrl,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendBroadcast').call({
        'title': title,
        'body': body,
        'targetCities': cities,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (customData != null) 'data': customData,
      });

      return BroadcastResult.fromJson(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send notification to specific users
  Future<BroadcastResult> sendToUsers({
    required String title,
    required String body,
    required List<String> userIds,
    String? imageUrl,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendBroadcast').call({
        'title': title,
        'body': body,
        'targetUserIds': userIds,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (customData != null) 'data': customData,
      });

      return BroadcastResult.fromJson(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // This is a simple check - in production you might want to cache this
      // or use custom claims
      final result = await _functions.httpsCallable('checkAdminStatus').call();
      return result.data['isAdmin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  String _handleError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return '請先登入才能發送通知';
      case 'permission-denied':
        return '您沒有權限發送廣播通知';
      case 'invalid-argument':
        return '請求參數無效: ${e.message}';
      case 'not-found':
        return '找不到符合條件的用戶';
      default:
        return '發送通知時發生錯誤: ${e.message}';
    }
  }
}

/// Result of a broadcast notification
class BroadcastResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final int totalTargets;
  final String? messageId; // For 'all users' broadcasts

  BroadcastResult({
    required this.success,
    required this.successCount,
    required this.failureCount,
    required this.totalTargets,
    this.messageId,
  });

  factory BroadcastResult.fromJson(Map<String, dynamic> json) {
    return BroadcastResult(
      success: json['success'] ?? false,
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
      totalTargets: json['totalTargets'] ?? 0,
      messageId: json['messageId'],
    );
  }

  double get successRate => 
      totalTargets > 0 ? (successCount / totalTargets) * 100 : 0;

  @override
  String toString() {
    return 'BroadcastResult(success: $success, sent: $successCount/$totalTargets, '
           'failed: $failureCount, success rate: ${successRate.toStringAsFixed(1)}%)';
  }
}
