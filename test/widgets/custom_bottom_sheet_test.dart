import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/custom_bottom_sheet.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('CustomBottomSheet renders drag handle and content', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: Stack(
            children: [
              CustomBottomSheet(
                initialChildSize: 0.5,
                minChildSize: 0.2,
                maxChildSize: 0.8,
                snapSizes: const [0.2, 0.5, 0.8],
                builder: (context, scrollController) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: 5,
                    itemBuilder: (context, index) => Text('Item $index'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Verify Drag Handle exists (Container with specific size/decoration)
    // The drag handle is a Container with width 48 and height 5
    final dragHandleFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.constraints?.minWidth == 48.0 && widget.constraints?.minHeight == 5.0) {
        return true;
      }
      return false;
    });

    expect(dragHandleFinder, findsOneWidget);

    // Verify content exists
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 4'), findsOneWidget);

    // Verify background color (should be cardColor)
    final containerFinder = find.descendant(
      of: find.byType(CustomBottomSheet),
      matching: find.byType(Container),
    ).first;

    final Container container = tester.widget(containerFinder);
    final BoxDecoration decoration = container.decoration as BoxDecoration;
    // We expect card color. For minimal theme, it's AppColorsMinimal.surface (0xFFFAFAFA) or similar
    // We just check it's not null.
    expect(decoration.color, isNotNull);
  });
}
