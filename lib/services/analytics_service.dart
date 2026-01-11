import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// A wrapper service for Firebase Analytics to track key user behaviors.
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Local log for debug purposes
  final List<String> _localLog = [];
  List<String> get localLog => List.unmodifiable(_localLog);

  void _logToLocal(String event, [Map<String, dynamic>? parameters]) {
    if (kDebugMode) {
      final log = '${DateTime.now().toIso8601String()}: $event $parameters';
      debugPrint('[Analytics] $log');
      _localLog.insert(0, log);
      if (_localLog.length > 50) {
        _localLog.removeLast();
      }
    }
  }

  /// Sets the user ID for analytics tracking.
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
    _logToLocal('setUserId', {'id': id});
  }

  /// Tracks user login events.
  /// [method] can be 'email', 'google', 'apple', etc.
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    _logToLocal('login', {'method': method});
  }

  /// Tracks user sign up events.
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    _logToLocal('sign_up', {'method': method});
  }

  /// Tracks screen views.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    _logToLocal('screen_view', {'screenName': screenName});
  }

  /// Tracks matching actions (swipes).
  /// [swipeType] can be 'like', 'dislike', 'super_like'.
  /// [isMatch] indicates if the swipe resulted in a match.
  Future<void> logSwipe({
    required String swipeType,
    required bool isMatch,
    String? partnerId,
  }) async {
    await _analytics.logEvent(
      name: 'swipe_action',
      parameters: {
        'swipe_type': swipeType,
        'is_match': isMatch ? 1 : 0,
        if (partnerId != null) 'partner_id': partnerId,
      },
    );
    _logToLocal('swipe_action', {'type': swipeType, 'match': isMatch});
  }

  /// Tracks when a user starts a chat (first message or new match chat).
  Future<void> logChatStart({required String chatRoomId}) async {
    await _analytics.logEvent(
      name: 'chat_start',
      parameters: {
        'chat_room_id': chatRoomId,
      },
    );
    _logToLocal('chat_start', {'chatRoomId': chatRoomId});
  }

  /// Tracks messaging events.
  /// [messageType] can be 'text', 'image', 'audio', 'sticker'.
  Future<void> logMessageSent({required String messageType}) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'message_type': messageType,
      },
    );
    _logToLocal('message_sent', {'type': messageType});
  }

  /// Tracks event participation.
  Future<void> logEventRegistration({
    required String eventId,
    required String eventName,
  }) async {
    await _analytics.logEvent(
      name: 'event_registration',
      parameters: {
        'event_id': eventId,
        'event_name': eventName,
      },
    );
    _logToLocal('event_registration', {'eventId': eventId});
  }

  /// Tracks event cancellation.
  Future<void> logEventCancellation({
    required String eventId,
    required String eventName,
  }) async {
    await _analytics.logEvent(
      name: 'event_cancellation',
      parameters: {
        'event_id': eventId,
        'event_name': eventName,
      },
    );
    _logToLocal('event_cancellation', {'eventId': eventId});
  }

  /// Tracks custom events.
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
    _logToLocal(name, parameters);
  }
}
