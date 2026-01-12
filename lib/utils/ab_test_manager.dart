import 'package:flutter/foundation.dart';

/// A/B Testing Manager
///
/// 提供基於用戶 ID 的確定性 A/B 測試和功能開關功能。
/// Supports feature toggles and weighted variant distribution.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() => _instance;

  ABTestManager._internal();

  String? _userId;
  final Map<String, dynamic> _overrides = {};

  /// 初始化 A/B 測試管理器
  ///
  /// 必須在應用啟動或用戶登入後調用。
  void initialize(String userId) {
    _userId = userId;
    debugPrint('ABTestManager initialized for user: $userId');
  }

  /// 檢查功能是否開啟
  ///
  /// [featureKey] 功能標識符
  /// [trafficAllocation] 流量分配比例 (0.0 - 1.0)，默認為 1.0 (全量)
  ///
  /// 如果用戶未初始化，返回 false。
  bool isFeatureEnabled(String featureKey, {double trafficAllocation = 1.0}) {
    if (_overrides.containsKey(featureKey)) {
      return _overrides[featureKey] as bool;
    }

    if (_userId == null) {
      debugPrint('Warning: ABTestManager not initialized. Returning false for $featureKey');
      return false;
    }

    if (trafficAllocation >= 1.0) return true;
    if (trafficAllocation <= 0.0) return false;

    final hash = _djb2('${_userId}_$featureKey');
    final normalizedHash = (hash.abs() % 100) / 100.0;

    return normalizedHash < trafficAllocation;
  }

  /// 獲取實驗變體
  ///
  /// [experimentKey] 實驗標識符
  /// [variants] 變體列表 (例如 ['A', 'B'])
  /// [weights] 變體權重列表 (和必須為 1.0)，默認為均分
  ///
  /// 如果用戶未初始化，返回第一個變體。
  T getVariant<T>(String experimentKey, List<T> variants, {List<double>? weights}) {
    if (_overrides.containsKey(experimentKey)) {
      return _overrides[experimentKey] as T;
    }

    if (variants.isEmpty) {
      throw ArgumentError('Variants list cannot be empty');
    }

    if (_userId == null) {
      debugPrint('Warning: ABTestManager not initialized. Returning first variant for $experimentKey');
      return variants.first;
    }

    final effectiveWeights = weights ?? List.filled(variants.length, 1.0 / variants.length);

    if (effectiveWeights.length != variants.length) {
       throw ArgumentError('Weights length must match variants length');
    }

    // 驗證權重總和是否接近 1.0 (允許微小誤差)
    final weightSum = effectiveWeights.reduce((a, b) => a + b);
    if ((weightSum - 1.0).abs() > 0.001) {
       debugPrint('Warning: Weights sum to $weightSum, not 1.0');
    }

    final hash = _djb2('${_userId}_$experimentKey');
    final normalizedHash = (hash.abs() % 100) / 100.0;

    double cumulativeWeight = 0.0;
    for (int i = 0; i < variants.length; i++) {
      cumulativeWeight += effectiveWeights[i];
      if (normalizedHash < cumulativeWeight) {
        return variants[i];
      }
    }

    return variants.last;
  }

  /// 設置測試覆蓋值
  void setOverride(String key, dynamic value) {
    _overrides[key] = value;
  }

  /// 清除所有覆蓋值
  void clearOverrides() {
    _overrides.clear();
  }

  /// 重置狀態 (登出時使用)
  void reset() {
    _userId = null;
    _overrides.clear();
  }

  /// DJB2 Hash Algorithm implementation
  ///
  /// Used for deterministic assignment based on user ID and key.
  int _djb2(String str) {
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
    }
    return hash;
  }
}
