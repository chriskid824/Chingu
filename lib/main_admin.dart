import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'admin/admin_app.dart';

/// Chingu 營運後台 — Web 入口
/// 與行動 App `main.dart` 並行，共用 Firebase 專案。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('zh_TW', null);
  if (kDebugMode) debugPrint('Chingu Admin started');
  runApp(const AdminApp());
}
