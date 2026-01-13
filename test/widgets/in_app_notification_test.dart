import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

// HttpOverrides to intercept network calls from CachedNetworkImage
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return a dummy implementation for properties not explicitly implemented
    // This simple mock is sufficient to return a request object
    return null;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest();
  }
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse();
  }

  @override
  HttpHeaders get headers => _TestHttpHeaders();
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _TestHttpClientResponse implements HttpClientResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0; // Empty image

  @override
  Stream<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // Return an empty stream immediately to simulate a completed empty response
    // or a minimal valid transparent 1x1 GIF if needed.
    // For CachedNetworkImage, an empty response might trigger error builder or placeholder.
    // Let's return a tiny valid GIF to be safe.
    const List<int> transparentGif = [
      0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00,
      0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x01, 0x00,
      0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44,
      0x01, 0x00, 0x3b
    ];

    onData?.call(transparentGif);
    onDone?.call();
    return Stream.value(transparentGif);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  // Helper to create the test widget wrapped in the app theme
  Widget createTestWidget(NotificationModel notification, {VoidCallback? onDismiss, VoidCallback? onTap}) {
    // Using Minimal preset to ensure ChinguTheme is available
    final theme = AppTheme.themeFor(AppThemePreset.minimal);

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: InAppNotification(
          notification: notification,
          onDismiss: onDismiss,
          onTap: onTap,
        ),
      ),
    );
  }

  testWidgets('InAppNotification renders title and message', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(notification));

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Message'), findsOneWidget);
  });

  testWidgets('InAppNotification renders correct icon for match type', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'match',
      title: 'Match Title',
      message: 'Match Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(notification));

    // 'match' type maps to 'favorite' iconName, which maps to Icons.favorite_rounded
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('InAppNotification renders dismiss button when onDismiss is provided', (WidgetTester tester) async {
    bool dismissed = false;
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Dismiss Me',
      message: 'Dismiss Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(
      notification,
      onDismiss: () => dismissed = true,
    ));

    final dismissButton = find.byIcon(Icons.close_rounded);
    expect(dismissButton, findsOneWidget);

    await tester.tap(dismissButton);
    expect(dismissed, isTrue);
  });

  testWidgets('InAppNotification triggers onTap callback', (WidgetTester tester) async {
    bool tapped = false;
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Tap Me',
      message: 'Tap Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(
      notification,
      onTap: () => tapped = true,
    ));

    await tester.tap(find.byType(InAppNotification));
    expect(tapped, isTrue);
  });

  testWidgets('InAppNotification handles missing image gracefully', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'event',
      title: 'Event Title',
      message: 'Event Message',
      // No imageUrl provided
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(notification));

    // Should render the fallback icon for 'event' -> Icons.calendar_today_rounded
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    // Should not find CachedNetworkImage since imageUrl is null
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

   testWidgets('InAppNotification renders CachedNetworkImage when imageUrl is present', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'event',
      title: 'Event Title',
      message: 'Event Message',
      imageUrl: 'https://example.com/image.jpg',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(notification));
    await tester.pumpAndSettle(); // Allow image loading to complete (mocked)

    // Verify CachedNetworkImage is in the tree
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
