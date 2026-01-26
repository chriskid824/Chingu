import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/login_history_model.dart';

/// 認證狀態枚舉
enum AuthStatus {
  uninitialized, // 未初始化
  authenticated, // 已認證
  unauthenticated, // 未認證
}

/// 認證 Provider - 管理用戶認證狀態
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.uninitialized;
  firebase_auth.User? _firebaseUser;
  UserModel? _userModel;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get uid => _firebaseUser?.uid;

  AuthProvider() {
    // 監聽認證狀態變化
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// 處理認證狀態變化
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      // 用戶登出
      _status = AuthStatus.unauthenticated;
      _firebaseUser = null;
      _userModel = null;
    } else {
      // 用戶登入
      _firebaseUser = firebaseUser;
      await _loadUserData(firebaseUser.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  /// 載入用戶資料
  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);

      if (_userModel != null) {
        // 更新最後登入時間
        await _firestoreService.updateLastLogin(uid);
      } else {
        // 用戶文檔不存在
        _errorMessage = '找不到用戶資料 (Document Not Found)';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('載入用戶資料失敗: $e');
      _errorMessage = '載入資料失敗: $e';
      _userModel = null;
      notifyListeners();
    }
  }

  /// 註冊新用戶
  /// 
  /// [email] 電子郵件
  /// [password] 密碼
  /// [name] 姓名
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // 1. 在 Firebase Auth 創建用戶
      final firebaseUser = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. 更新顯示名稱
      await _authService.updateDisplayName(name);

      // 3. 在 Firestore 創建用戶資料（基本資料，詳細資料在 onboarding 中完成）
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        age: 0, // 將在 onboarding 中設置
        gender: '', // 將在 onboarding 中設置
        job: '', // 將在 onboarding 中設置
        interests: [], // 將在 onboarding 中設置
        country: '台灣', // 預設值
        city: '', // 將在 onboarding 中設置
        district: '', // 將在 onboarding 中設置
        preferredMatchType: 'any', // 預設值
        minAge: 18, // 預設值
        maxAge: 100, // 預設值
        budgetRange: 1, // 預設值
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestoreService.createUser(userModel);

      // 4. 立即重新載入用戶資料，確保 _userModel 不為空
      // 這解決了註冊後立即跳轉導致資料尚未載入的競態條件
      await _loadUserData(firebaseUser.uid);

      // 5. 記錄登入歷史
      _recordLogin(firebaseUser.uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 登入
  /// 
  /// [email] 電子郵件
  /// [password] 密碼
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 記錄登入歷史
      _recordLogin(user.uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Google 登入
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final firebaseUser = await _authService.signInWithGoogle();

      // 檢查是否為新用戶
      final exists = await _firestoreService.userExists(firebaseUser.uid);

      if (!exists) {
        // 為新的 Google 用戶創建 Firestore 資料
        final userModel = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL,
          age: 0, // 將在 onboarding 中設置
          gender: '', // 將在 onboarding 中設置
          job: '', // 將在 onboarding 中設置
          interests: [], // 將在 onboarding 中設置
          country: '台灣', // 預設值
          city: '', // 將在 onboarding 中設置
          district: '', // 將在 onboarding 中設置
          preferredMatchType: 'any', // 預設值
          minAge: 18, // 預設值
          maxAge: 100, // 預設值
          budgetRange: 1, // 預設值
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);
      }

      // 記錄登入歷史
      _recordLogin(firebaseUser.uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 發送密碼重設郵件
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.sendPasswordResetEmail(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 更新用戶資料
  /// 
  /// [data] 要更新的資料
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_firebaseUser == null) return false;

      _setLoading(true);
      _errorMessage = null;

      await _firestoreService.updateUser(_firebaseUser!.uid, data);

      // 重新載入用戶資料
      await _loadUserData(_firebaseUser!.uid);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 檢查用戶是否完成 Onboarding
  bool hasCompletedOnboarding() {
    if (_userModel == null) return false;

    // 檢查必填欄位是否已填寫
    return _userModel!.age > 0 &&
        _userModel!.gender.isNotEmpty &&
        _userModel!.job.isNotEmpty &&
        _userModel!.city.isNotEmpty;
  }

  /// 刷新用戶資料
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  /// 設置載入狀態
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 清除錯誤訊息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 記錄登入歷史
  Future<void> _recordLogin(String uid) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      String deviceOs = 'Unknown';

      if (kIsWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;
        deviceName = webBrowserInfo.userAgent ?? 'Web Browser';
        deviceOs = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceOs = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        deviceOs = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      // 獲取 IP 和位置
      String ipAddress = 'Unknown';
      String location = 'Unknown';

      try {
        final response =
            await http.get(Uri.parse('http://ip-api.com/json')).timeout(
          const Duration(seconds: 5),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          ipAddress = data['query'] ?? 'Unknown';
          final city = data['city'] ?? '';
          final country = data['country'] ?? '';
          if (city.isNotEmpty || country.isNotEmpty) {
            location = '$city, $country'.trim();
            if (location.startsWith(',')) location = location.substring(1).trim();
            if (location.endsWith(',')) location = location.substring(0, location.length - 1).trim();
          }
        }
      } catch (e) {
        debugPrint('獲取 IP 失敗: $e');
      }

      final history = LoginHistoryModel(
        id: '', // Firestore 會自動生成 ID，這裡留空或在 Service 處理
        uid: uid,
        timestamp: DateTime.now(),
        deviceName: deviceName,
        deviceOs: deviceOs,
        ipAddress: ipAddress,
        location: location,
      );

      await _firestoreService.recordLoginHistory(history);
    } catch (e) {
      debugPrint('記錄登入歷史錯誤: $e');
    }
  }
}



