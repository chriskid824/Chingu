import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chingu/screens/chat/chat_detail_screen.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:network_image_mock/network_image_mock.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockChatProvider extends Mock implements ChatProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockChatProvider mockChatProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockChatProvider = MockChatProvider();
  });

  Widget createWidgetUnderTest() {
    final mockUser = UserModel(
      uid: 'user123',
      name: 'Tester',
      email: 'test@example.com',
      age: 28,
      gender: 'male',
      job: 'Software Engineer',
      interests: ['Coding', 'Reading'],
      country: 'Taiwan',
      city: 'Taipei',
      district: 'Xinyi',
      diningPreference: 'any',
      minAge: 20,
      maxAge: 40,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    final mockOtherUser = UserModel(
      uid: 'other456',
      name: 'Other',
      email: 'other@example.com',
      age: 26,
      gender: 'female',
      job: 'Designer',
      interests: ['Art', 'Music'],
      country: 'Taiwan',
      city: 'Taipei',
      district: 'Da\'an',
      diningPreference: 'male',
      minAge: 25,
      maxAge: 35,
      budgetRange: 2,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    when(() => mockAuthProvider.userModel).thenReturn(mockUser);
    when(() => mockAuthProvider.uid).thenReturn('user123');

    // 模擬已載入的對話
    when(() => mockChatProvider.getMessages('room123')).thenAnswer(
      (_) => Stream.value([
        {'text': 'Hello', 'senderId': 'other456'},
      ]),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => const ChatDetailScreen(),
              settings: RouteSettings(
                arguments: {
                  'chatRoomId': 'room123',
                  'otherUser': mockOtherUser,
                },
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  group('ChatDetailScreen Widget Test', () {
    testWidgets('應成功發送文字訊息', (WidgetTester tester) async {
      // 由於畫面內可能載入對方的頭像網絡圖片，需要包裹 mock
      await mockNetworkImagesFor(() async {
        when(() => mockChatProvider.sendMessage(
              chatRoomId: any(named: 'chatRoomId'),
              senderId: any(named: 'senderId'),
              text: any(named: 'text'),
            )).thenAnswer((_) async => null);

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // 尋找文字輸入框並輸入測試訊息
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'This is a test message from WidgetTest');
        await tester.pump();

        // 尋找發送按鈕
        final sendButton = find.byIcon(Icons.send_rounded);
        expect(sendButton, findsOneWidget);
        
        // 點擊送出
        await tester.ensureVisible(sendButton);
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // 驗證 Provider 方法是否被呼叫，確保發送邏輯未被破壞
        verify(() => mockChatProvider.sendMessage(
              chatRoomId: 'room123',
              senderId: 'user123',
              text: 'This is a test message from WidgetTest',
            )).called(1);
      });
    });
  });
}
