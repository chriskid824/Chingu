import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../core/routes/app_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize() async {
    // Check initial link
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to link stream
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    // Handle /invite?code=XYZ
    if (pathSegments[0] == 'invite') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        navigator.pushNamed(
          AppRoutes.register,
          arguments: {'inviteCode': code},
        );
      }
      return;
    }

    // Handle /event/:id
    if (pathSegments[0] == 'event' && pathSegments.length > 1) {
      final eventId = pathSegments[1];
      navigator.pushNamed(
        AppRoutes.eventDetail,
        arguments: eventId,
      );
      return;
    }

    // Handle /user/:id
    if (pathSegments[0] == 'user' && pathSegments.length > 1) {
      final userId = pathSegments[1];
      navigator.pushNamed(
        AppRoutes.userDetail,
        arguments: userId,
      );
      return;
    }

    // Fallback or other handling
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
