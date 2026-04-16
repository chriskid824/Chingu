import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';

/// 後台登入狀態 + 管理員權限驗證
class AdminAuthProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedInAsAdmin => _currentUser != null && _isAdmin;

  AdminAuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _currentUser = user;
      if (user != null) {
        _isAdmin = await _adminService.isCurrentUserAdmin();
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isAdmin = await _adminService.isCurrentUserAdmin();
      if (!_isAdmin) {
        await FirebaseAuth.instance.signOut();
        _errorMessage = '此帳號非管理員，請聯繫 super-admin 加入 /admins';
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '帳號或密碼錯誤';
      case 'too-many-requests':
        return '嘗試次數過多，請稍後再試';
      default:
        return '登入失敗：$code';
    }
  }
}
