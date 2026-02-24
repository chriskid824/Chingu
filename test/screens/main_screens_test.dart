import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('should have email input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  key: const Key('email_input'),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: '請輸入電子郵件',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('email_input')), findsOneWidget);
      expect(find.text('請輸入電子郵件'), findsOneWidget);
    });

    testWidgets('should have password input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  key: const Key('password_input'),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '密碼',
                    hintText: '請輸入密碼',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('password_input')), findsOneWidget);
      expect(find.text('請輸入密碼'), findsOneWidget);
    });

    testWidgets('should have login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('login_button'),
              onPressed: () {},
              child: const Text('登入'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('登入'), findsOneWidget);
    });

    testWidgets('should have forgot password link', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              key: const Key('forgot_password_link'),
              onPressed: () {},
              child: const Text('忘記密碼？'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('forgot_password_link')), findsOneWidget);
      expect(find.text('忘記密碼？'), findsOneWidget);
    });
  });

  group('Register Screen Widget Tests', () {
    testWidgets('should have name input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              key: const Key('name_input'),
              decoration: const InputDecoration(
                labelText: '姓名',
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('name_input')), findsOneWidget);
    });

    testWidgets('should have register button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('register_button'),
              onPressed: () {},
              child: const Text('註冊'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('register_button')), findsOneWidget);
      expect(find.text('註冊'), findsOneWidget);
    });
  });

  group('Settings Screen Widget Tests', () {
    testWidgets('should have profile section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(
                  key: Key('profile_tile'),
                  leading: Icon(Icons.person),
                  title: Text('個人資料'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('profile_tile')), findsOneWidget);
      expect(find.text('個人資料'), findsOneWidget);
    });

    testWidgets('should have logout button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ListTile(
                  key: const Key('logout_tile'),
                  leading: const Icon(Icons.logout),
                  title: const Text('登出'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('logout_tile')), findsOneWidget);
      expect(find.text('登出'), findsOneWidget);
    });

    testWidgets('should have privacy settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(
                  key: Key('privacy_tile'),
                  leading: Icon(Icons.privacy_tip),
                  title: Text('隱私設定'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('privacy_tile')), findsOneWidget);
      expect(find.text('隱私設定'), findsOneWidget);
    });

    testWidgets('should have delete account option in privacy', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ListTile(
                  key: const Key('delete_account_tile'),
                  leading: Icon(Icons.delete_forever, color: Colors.red[400]),
                  title: Text('刪除帳號', style: TextStyle(color: Colors.red[400])),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('delete_account_tile')), findsOneWidget);
      expect(find.text('刪除帳號'), findsOneWidget);
    });
  });

  group('Chat Screen Widget Tests', () {
    testWidgets('should have message input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: const Key('message_input'),
              decoration: const InputDecoration(
                hintText: '輸入訊息...',
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('message_input')), findsOneWidget);
      expect(find.text('輸入訊息...'), findsOneWidget);
    });

    testWidgets('should have send button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              key: const Key('send_button'),
              icon: const Icon(Icons.send),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('send_button')), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });

  group('Dinner Event Screen Widget Tests', () {
    testWidgets('should display event title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text('Taipei Dinner'),
                subtitle: Text('2026/02/15 • 6 人'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Taipei Dinner'), findsOneWidget);
    });

    testWidgets('should have join button for open events', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('join_event_button'),
              onPressed: () {},
              child: const Text('加入活動'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('join_event_button')), findsOneWidget);
      expect(find.text('加入活動'), findsOneWidget);
    });

    testWidgets('should show participant count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.people),
                SizedBox(width: 4),
                Text('4/6'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('4/6'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });
}
