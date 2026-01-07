import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import '../../lib/core/widgets/primary_button.dart';

@widgetbook.UseCase(
  name: 'Primary Button',
  type: PrimaryButton,
)
Widget primaryButtonUseCase(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PrimaryButton(
            text: '主要按鈕',
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '載入中',
            isLoading: true,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '禁用狀態',
            onPressed: null,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '帶圖標',
            icon: Icons.login,
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Secondary Button',
  type: SecondaryButton,
)
Widget secondaryButtonUseCase(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SecondaryButton(
            text: '次要按鈕',
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: '帶圖標',
            icon: Icons.edit,
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}



