import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

/// 強制更新服務
/// 
/// 透過 Firebase Remote Config 控制最低版本號。
/// 在 Firebase Console → Remote Config 設定：
///   - min_app_version: "1.0.0"   ← 最低可用版本
///   - force_update_message: "..."  ← 自訂更新訊息（選用）
class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._();

  final _remoteConfig = FirebaseRemoteConfig.instance;

  /// 初始化 Remote Config 並檢查版本
  /// 回傳 true = 需要強制更新
  Future<bool> checkForUpdate() async {
    try {
      // 設定預設值
      await _remoteConfig.setDefaults({
        'min_app_version': '1.0.0',
        'force_update_message': '我們推出了重要更新，請更新到最新版本以繼續使用 Chingu。',
      });

      // 設定快取策略（每 1 小時檢查一次）
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // 拉取最新值
      await _remoteConfig.fetchAndActivate();

      // 比較版本
      final minVersion = _remoteConfig.getString('min_app_version');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      return _isVersionOlder(currentVersion, minVersion);
    } catch (e) {
      debugPrint('⚠️ ForceUpdate 檢查失敗: $e');
      // 檢查失敗不阻擋用戶
      return false;
    }
  }

  /// 取得更新訊息
  String get updateMessage =>
      _remoteConfig.getString('force_update_message');

  /// 顯示強制更新對話框（不可關閉）
  static Future<void> showUpdateDialog(BuildContext context) async {
    final service = ForceUpdateService();

    await showDialog(
      context: context,
      barrierDismissible: false, // 不可點外部關閉
      builder: (ctx) => PopScope(
        canPop: false, // 不可返回鍵關閉
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColorsMinimal.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColorsMinimal.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '需要更新',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            service.updateMessage,
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openStore(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsMinimal.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '前往更新',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 開啟 App Store / Play Store
  static Future<void> _openStore() async {
    final Uri storeUrl;
    if (Platform.isIOS) {
      // 替換為你的 App Store ID
      storeUrl = Uri.parse('https://apps.apple.com/app/chingu/id000000000');
    } else {
      storeUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.chingu.chingu');
    }

    if (await canLaunchUrl(storeUrl)) {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// 版本比較：currentVersion < minVersion → true（需更新）
  bool _isVersionOlder(String current, String min) {
    try {
      final currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final minParts = min.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (var i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false; // 相等 = 不需要更新
    } catch (e) {
      debugPrint('⚠️ 版本比較失敗: $e');
      return false;
    }
  }
}
