import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A/B Testing Manager
/// 支持功能開關和變體測試
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  factory ABTestManager() => _instance;
  ABTestManager._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseFirestore get _firestore => 
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => 
      _authInstance ??= FirebaseAuth.instance;

  // 本地緩存的測試配置
  final Map<String, ABTestConfig> _cachedTests = {};
  
  // 用戶的變體分配緩存
  final Map<String, String> _userVariants = {};

  /// 設置依賴項 (用於測試)
  @visibleForTesting
  void setDependencies({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    _firestoreInstance = firestore;
    _authInstance = auth;
  }

  /// 初始化 A/B 測試管理器
  /// 從 Firestore 加載配置
  Future<void> initialize() async {
    try {
      final snapshot = await _firestore
          .collection('ab_tests')
          .where('isActive', isEqualTo: true)
          .get();

      _cachedTests.clear();
      for (var doc in snapshot.docs) {
        final config = ABTestConfig.fromFirestore(doc);
        _cachedTests[config.testId] = config;
      }

      // 加載用戶的變體分配
      await _loadUserVariants();
    } catch (e) {
      debugPrint('Failed to initialize ABTestManager: $e');
    }
  }

  /// 加載用戶已分配的變體
  Future<void> _loadUserVariants() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ab_test_variants')
          .get();

      _userVariants.clear();
      for (var doc in snapshot.docs) {
        _userVariants[doc.id] = doc.data()['variant'] as String;
      }
    } catch (e) {
      debugPrint('Failed to load user variants: $e');
    }
  }

  /// 獲取用戶在特定測試中的變體
  /// 如果用戶尚未分配變體,則自動分配
  Future<String> getVariant(String testId) async {
    // 檢查緩存
    if (_userVariants.containsKey(testId)) {
      return _userVariants[testId]!;
    }

    // 檢查測試配置
    final config = _cachedTests[testId];
    if (config == null) {
      return 'control'; // 默認返回對照組
    }

    // 分配新變體
    final variant = _assignVariant(config);
    
    // 如果用戶已登入，保存分配結果
    if (_auth.currentUser != null) {
      await _saveVariantAssignment(testId, variant);
      _userVariants[testId] = variant;
    }

    return variant;
  }

  /// 生成確定性的哈希值
  int _getHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash;
  }

  /// 分配變體(基於權重和用戶ID的確定性算法)
  String _assignVariant(ABTestConfig config) {
    final userId = _auth.currentUser?.uid;
    double randomValue;

    if (userId != null) {
      // 基於用戶ID和測試ID生成確定性的隨機值 (0-100)
      final hash = _getHash('${userId}_${config.testId}');
      randomValue = (hash.abs() % 10000) / 100.0;
    } else {
      // 未登入用戶使用隨機分配
      randomValue = (DateTime.now().microsecondsSinceEpoch % 10000) / 100.0;
    }

    var cumulative = 0.0;
    for (var variant in config.variants) {
      cumulative += variant.weight;
      if (randomValue < cumulative) {
        return variant.name;
      }
    }

    return config.variants.isNotEmpty ? config.variants.first.name : 'control';
  }

  /// 保存用戶的變體分配到 Firestore
  Future<void> _saveVariantAssignment(String testId, String variant) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ab_test_variants')
          .doc(testId)
          .set({
        'variant': variant,
        'assignedAt': FieldValue.serverTimestamp(),
        'testId': testId,
      });
    } catch (e) {
      debugPrint('Failed to save variant assignment: $e');
    }
  }

  /// 檢查功能開關是否啟用
  /// 支持 A/B 測試和簡單的功能開關
  Future<bool> isFeatureEnabled(
    String featureKey, {
    String? specificVariant,
  }) async {
    // 嘗試作為 A/B 測試
    if (_cachedTests.containsKey(featureKey)) {
      final variant = await getVariant(featureKey);
      if (specificVariant != null) {
        return variant == specificVariant;
      }
      // 默認: 非 control 變體返回 true
      return variant != 'control';
    }

    // 作為簡單功能開關檢查
    final config = await _getFeatureConfig(featureKey);
    return config?.enabled ?? false;
  }

  /// 獲取功能配置(用於簡單開關)
  Future<FeatureConfig?> _getFeatureConfig(String featureKey) async {
    try {
      final doc = await _firestore
          .collection('feature_flags')
          .doc(featureKey)
          .get();

      if (!doc.exists) return null;
      return FeatureConfig.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// 記錄測試事件(用於分析)
  Future<void> trackEvent(
    String testId,
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final variant = _userVariants[testId] ?? 'unknown';

    try {
      await _firestore.collection('ab_test_events').add({
        'testId': testId,
        'userId': userId,
        'variant': variant,
        'eventName': eventName,
        'properties': properties ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to track event: $e');
    }
  }

  /// 獲取用戶當前所有的變體分配
  Map<String, String> getUserVariants() {
    return Map.from(_userVariants);
  }

  /// 清除緩存(用於測試)
  @visibleForTesting
  void clearCache() {
    _cachedTests.clear();
    _userVariants.clear();
  }

  /// 強制刷新配置
  Future<void> refresh() async {
    await initialize();
  }
}

/// A/B 測試配置
class ABTestConfig {
  final String testId;
  final String name;
  final String description;
  final bool isActive;
  final List<ABTestVariant> variants;
  final DateTime? startDate;
  final DateTime? endDate;

  ABTestConfig({
    required this.testId,
    required this.name,
    required this.description,
    required this.isActive,
    required this.variants,
    this.startDate,
    this.endDate,
  });

  factory ABTestConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ABTestConfig(
      testId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? false,
      variants: (data['variants'] as List<dynamic>? ?? [])
          .map((v) => ABTestVariant.fromMap(v as Map<String, dynamic>))
          .toList(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'variants': variants.map((v) => v.toMap()).toList(),
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }
}

/// A/B 測試變體
class ABTestVariant {
  final String name;
  final double weight; // 權重 (0-100)
  final Map<String, dynamic> config;

  ABTestVariant({
    required this.name,
    required this.weight,
    this.config = const {},
  });

  factory ABTestVariant.fromMap(Map<String, dynamic> map) {
    return ABTestVariant(
      name: map['name'] ?? '',
      weight: (map['weight'] ?? 50.0).toDouble(),
      config: map['config'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'config': config,
    };
  }
}

/// 簡單功能開關配置
class FeatureConfig {
  final String key;
  final bool enabled;
  final Map<String, dynamic> config;

  FeatureConfig({
    required this.key,
    required this.enabled,
    this.config = const {},
  });

  factory FeatureConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FeatureConfig(
      key: doc.id,
      enabled: data['enabled'] ?? false,
      config: data['config'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'config': config,
    };
  }
}
