import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
    await _requestPermission();

    // 2. Initialize Local Notifications
    await _initLocalNotifications();

    // 3. Setup Foreground Message Handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Setup Background/Terminated Message Handler (App Opened from Notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Request Notification Permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  /// Initialize Local Notifications (for displaying foreground notifications)
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
         // Handle local notification tap
         debugPrint('Local notification tapped with payload: ${response.payload}');
         // You can add navigation logic here if needed
      },
    );

    // Create the channel on the device (if a channel with an id already exists,
    // it will be updated)
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // For iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Handle incoming foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: android.smallIcon,
            // other properties...
          ),
        ),
        payload: message.data.toString(), // Pass data as payload
      );
    }
  }

  /// Handle when app is opened from a notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    // Parse the message and navigate to the appropriate screen
    // Example: Navigator.pushNamed(context, '/chat', arguments: message.data);
    // Note: Since this is a service, you might need a GlobalKey<NavigatorState>
    // or a dedicated navigation service to handle navigation from here.
  }

  /// Get FCM Token
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Get Background Handler (to be passed to main)
  static Future<void> Function(RemoteMessage) get backgroundHandler => _firebaseMessagingBackgroundHandler;
}
