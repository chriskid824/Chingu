import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/models/user_model.dart';

/// 認證狀態枚舉
enum AuthStatus {
  uninitialized, // 未初始化
  authenticated, // 已認證
  unauthenticated, // 未認證
  requiresTwoFactor, // 需要雙因素認證
}

/// 認證 Provider - 管理用戶認證狀態
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TwoFactorAuthService _twoFactorAuthService = TwoFactorAuthService();

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
  bool get requiresTwoFactor => _status == AuthStatus.requiresTwoFactor;
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

      // 檢查是否開啟 2FA
      if (_userModel != null && _userModel!.isTwoFactorEnabled) {
        _status = AuthStatus.requiresTwoFactor;
      } else {
        _status = AuthStatus.authenticated;
      }
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

  /// 驗證雙因素代碼
  ///
  /// [code] 驗證碼
  Future<bool> verifyTwoFactor(String code) async {
    try {
      if (_userModel == null) return false;

      _setLoading(true);
      _errorMessage = null;

      // 決定目標 (Email 或 Phone)
      String target = _userModel!.email;
      if (_userModel!.twoFactorMethod == 'sms' && _userModel!.phoneNumber != null) {
        target = _userModel!.phoneNumber!;
      }

      await _twoFactorAuthService.verifyCode(target, code);

      // 驗證成功，更新狀態
      _status = AuthStatus.authenticated;

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

  /// 重新發送雙因素驗證碼
  Future<bool> resendTwoFactorCode() async {
    try {
      if (_userModel == null) return false;

      _setLoading(true);
      _errorMessage = null;

      String target = _userModel!.email;
      if (_userModel!.twoFactorMethod == 'sms' && _userModel!.phoneNumber != null) {
        target = _userModel!.phoneNumber!;
      }

      await _twoFactorAuthService.sendVerificationCode(
        target: target,
        method: _userModel!.twoFactorMethod,
        uid: _userModel!.uid,
      );

      _setLoading(false);
      // 注意: 這裡不改變 _status，因為仍然在需要驗證的狀態
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
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

      // 註冊後不應立即要求 2FA，除非我們強制作為流程一部分。
      // 目前假設新註冊用戶 2FA 為 false，所以會直接 authenticated.
      if (_userModel != null && _userModel!.isTwoFactorEnabled) {
         _status = AuthStatus.requiresTwoFactor;
      } else {
         _status = AuthStatus.authenticated;
      }

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

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 注意：這裡不需要手動調用 _loadUserData，因為 _onAuthStateChanged 會被觸發
      // 但是為了確保 signIn 返回時狀態已經正確（如果有異步延遲），
      // 依賴監聽器是比較安全的做法。
      // 不過 _onAuthStateChanged 是異步的，可能在 signIn 返回後才執行完成。
      // 所以UI應該監聽 AuthProvider 的狀態變化，而不是僅依賴 signIn 的返回值。

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

      // 同樣依賴 _onAuthStateChanged 更新狀態

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
}
