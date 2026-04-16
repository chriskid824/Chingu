import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 後台專用服務 — 管理員身份驗證 + 共用 Firestore 操作
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 檢查當前登入用戶是否為管理員
  /// 對齊 firestore.rules 的 isAdmin()：在 /admins/{uid} collection 中或 super-admin email
  Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (user.email == 'chriskid824@gmail.com') return true;

    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists;
  }

  /// 取得本週進行中的 DinnerEvent (status in ['matching','revealed'])
  Future<DocumentSnapshot?> getCurrentWeekEvent() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartTs = Timestamp.fromDate(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );

    final snap = await _db
        .collection('dinner_events')
        .where('eventDate', isGreaterThanOrEqualTo: weekStartTs)
        .orderBy('eventDate')
        .limit(1)
        .get();

    return snap.docs.isEmpty ? null : snap.docs.first;
  }
}
