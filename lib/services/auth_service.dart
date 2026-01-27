import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 認證服務 - 處理所有 Firebase Authentication 相關操作
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 獲取當前登入用戶
  User? get currentUser => _auth.currentUser;

  /// 用戶狀態變化流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 註冊新用戶（電子郵件/密碼）
  /// 
  /// [email] 電子郵件
  /// [password] 密碼
  /// 
  /// 返回 User 或拋出異常
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('註冊失敗，請稍後再試');
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('註冊過程發生錯誤: $e');
    }
  }

  /// 登入（電子郵件/密碼）
  /// 
  /// [email] 電子郵件
  /// [password] 密碼
  /// 
  /// 返回 User 或拋出異常
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('登入失敗，請稍後再試');
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('登入過程發生錯誤: $e');
    }
  }

  /// Google 登入
  /// 
  /// 返回 User 或拋出異常
  Future<User> signInWithGoogle() async {
    try {
      // 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google 登入已取消');
      }

      // 獲取認證詳細資訊
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 創建新的憑證
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用憑證登入 Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google 登入失敗');
      }

      return userCredential.user!;
    } catch (e) {
      throw Exception('Google 登入失敗: $e');
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('登出失敗: $e');
    }
  }

  /// 發送密碼重設郵件
  /// 
  /// [email] 電子郵件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('發送重設郵件失敗: $e');
    }
  }

  /// 更新用戶顯示名稱
  /// 
  /// [displayName] 顯示名稱
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('更新名稱失敗: $e');
    }
  }

  /// 更新用戶照片
  /// 
  /// [photoURL] 照片網址
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoURL);
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('更新照片失敗: $e');
    }
  }

  /// 重新認證用戶
  ///
  /// [password] 密碼（如果提供者是 password）
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('用戶未登入');

    try {
      // 檢查用戶的認證提供者
      // 優先檢查密碼提供者
      if (user.providerData.any((p) => p.providerId == 'password')) {
        if (password == null) throw Exception('需要密碼進行驗證');

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password
        );

        await user.reauthenticateWithCredential(credential);
        return;
      }

      // 檢查 Google 提供者
      if (user.providerData.any((p) => p.providerId == 'google.com')) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google 驗證已取消');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
        return;
      }

      throw Exception('未支援的認證方式，無法重新驗證');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('重新驗證失敗: $e');
    }
  }

  /// 刪除用戶帳號
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('此操作需要最近登入，請先登出再重新登入');
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('刪除帳號失敗: $e');
    }
  }

  /// 處理 Firebase Auth 異常
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '此電子郵件已被使用';
      case 'invalid-email':
        return '電子郵件格式不正確';
      case 'operation-not-allowed':
        return '此操作目前不可用';
      case 'weak-password':
        return '密碼強度不足（至少6個字元）';
      case 'user-disabled':
        return '此帳號已被停用';
      case 'user-not-found':
        return '找不到此用戶';
      case 'wrong-password':
        return '密碼錯誤';
      case 'too-many-requests':
        return '請求次數過多，請稍後再試';
      case 'network-request-failed':
        return '網路連線失敗，請檢查網路設定';
      default:
        return e.message ?? '認證過程發生錯誤';
    }
  }
}



