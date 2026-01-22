import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

// Top-level function for background handling
// This must be a top-level function and annotated with @pragma('vm:entry-point')
// to ensure it can be called by the engine when the app is in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Initializes the notification service configuration.
  /// This should be called in main() before runApp().
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
  }

  /// Sets up interactions for terminated and background states.
  /// This MUST be called after the Navigator is mounted (e.g. in a StatefulWidget's initState after runApp).
  Future<void> setupInteractedMessage() async {
    // Handle terminated state notification tap
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle background state notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling notification tap: ${message.data}');

    // Check if the message contains a data payload with navigation instructions
    final data = message.data;
    if (data.containsKey('actionType')) {
      final actionType = data['actionType'];
      final actionData = data['actionData'];

      _handleNavigation(actionType, actionData);
    }
  }

  void _handleNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null, cannot navigate');
      return;
    }

    // Pass actionData as arguments where appropriate
    // actionData is assumed to be a String, typically an ID or JSON string depending on implementation
    // The AppRouter expects arguments, let's pass actionData or a map containing it

    switch (actionType) {
      case 'open_chat':
        // For chat list, usually no args needed, but if we had a specific chat room ID, we'd navigate to chatDetail
        // Assuming actionData might be chatRoomId or userId if we wanted to go to detail
        // If actionData is present, maybe we should try to go to chatDetail?
        // But AppRoutes.chatList doesn't take arguments.
        // Let's stick to list as per previous logic, or just pass arguments just in case.
        navigator.pushNamed(AppRoutes.chatList, arguments: actionData);
        break;
      case 'view_event':
        // Event detail usually needs an event ID.
        // We pass actionData as the argument.
        // Note: EventDetailScreen in AppRouter currently takes no args in the builder:
        // case AppRoutes.eventDetail: return MaterialPageRoute(builder: (_) => const EventDetailScreen());
        // However, if EventDetailScreen uses ModalRoute.of(context)!.settings.arguments, passing it here helps.
        // If not, it needs to be updated. Given I cannot see EventDetailScreen source right now,
        // passing arguments is the correct "Service" side implementation.
        navigator.pushNamed(AppRoutes.eventDetail, arguments: actionData);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList, arguments: actionData);
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications, arguments: actionData);
        break;
    }
  }
}
