import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<String?> _tokenStreamController = StreamController<String?>.broadcast();

  Stream<String?> get tokenStream => _tokenStreamController.stream;

  Future<void> initialize() async {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
       _handleNavigation(message.data);
    });

    // App opened from terminated state
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state!');
        // Small delay to ensure navigator is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNavigation(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('Error handling initial message: $e');
    }

    // Get initial token
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        _tokenStreamController.add(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _tokenStreamController.add(newToken);
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  void _handleNavigation(Map<String, dynamic> data) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final String? actionType = data['actionType'];
    // ignore: unused_local_variable
    final String? actionData = data['actionData'];

    if (actionType != null) {
       switch (actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail);
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } else {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
     final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().toString(),
        userId: '',
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? '',
        message: message.notification?.body ?? '',
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
     );

     final overlayState = AppRouter.navigatorKey.currentState?.overlay;
     if (overlayState != null) {
       late OverlayEntry overlayEntry;
       overlayEntry = OverlayEntry(
         builder: (context) => _SlideInNotification(
           notification: notification,
           onDismiss: () {
             if (overlayEntry.mounted) {
               overlayEntry.remove();
             }
           },
           onTap: () {
             if (overlayEntry.mounted) {
               overlayEntry.remove();
             }
             _handleNavigation(message.data);
           },
         ),
       );

       overlayState.insert(overlayEntry);

       Future.delayed(const Duration(seconds: 4), () {
         if (overlayEntry.mounted) {
           overlayEntry.remove();
         }
       });
     }
  }
}

class _SlideInNotification extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SlideInNotification({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SlideInNotification> createState() => _SlideInNotificationState();
}

class _SlideInNotificationState extends State<_SlideInNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: ValueKey(widget.notification.id),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: InkWell(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.notification.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.notification.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.notifications, size: 40),
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notifications, color: Colors.blue),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.message,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
