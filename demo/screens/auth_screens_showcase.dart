import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import '../../lib/screens/auth/splash_screen.dart';

@widgetbook.UseCase(
  name: 'Splash Screen',
  type: SplashScreen,
)
Widget splashScreenUseCase(BuildContext context) {
  return const SplashScreen();
}



