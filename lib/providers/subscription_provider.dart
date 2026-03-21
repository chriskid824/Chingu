import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/subscription_model.dart';

/// 訂閱 Provider — 管理用戶付費狀態
class SubscriptionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SubscriptionModel? _subscription;
  bool _isLoading = false;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get canBook => _subscription?.canBook ?? false;
  bool get isPremium => _subscription?.isPremium ?? false;
  bool get isFreeTrial => _subscription?.isFreeTrial ?? false;
  int get freeTrialsRemaining => _subscription?.freeTrialsRemaining ?? 3;

  /// 載入用戶訂閱狀態
  Future<void> loadSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (doc.exists) {
        _subscription = SubscriptionModel.fromMap(doc.data()!, userId);
      } else {
        // 新用戶：給 3 次免費
        _subscription = SubscriptionModel(userId: userId);
        await _firestore
            .collection('subscriptions')
            .doc(userId)
            .set(_subscription!.toMap());
      }
    } catch (e) {
      debugPrint('[SubscriptionProvider] loadSubscription error: $e');
      // Fallback: 給 3 次免費
      _subscription = SubscriptionModel(userId: userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 消耗一次免費體驗
  Future<void> consumeFreeTrial(String userId) async {
    if (_subscription == null || _subscription!.freeTrialsRemaining <= 0) return;

    final updated = _subscription!.copyWith(
      freeTrialsRemaining: _subscription!.freeTrialsRemaining - 1,
    );

    await _firestore.collection('subscriptions').doc(userId).update({
      'freeTrialsRemaining': updated.freeTrialsRemaining,
    });

    _subscription = updated;
    notifyListeners();
  }

  /// 消耗一張單次票
  Future<void> consumeSingleTicket(String userId) async {
    if (_subscription == null || _subscription!.singleTickets <= 0) return;

    final updated = _subscription!.copyWith(
      singleTickets: _subscription!.singleTickets - 1,
    );

    await _firestore.collection('subscriptions').doc(userId).update({
      'singleTickets': updated.singleTickets,
    });

    _subscription = updated;
    notifyListeners();
  }

  /// 活動取消 → 退票補償
  Future<void> compensateCancellation(String userId) async {
    if (_subscription == null) return;

    if (_subscription!.isFreeTrial) {
      // 免費體驗期 → 退回 1 次
      final updated = _subscription!.copyWith(
        freeTrialsRemaining: _subscription!.freeTrialsRemaining + 1,
      );
      await _firestore.collection('subscriptions').doc(userId).update({
        'freeTrialsRemaining': updated.freeTrialsRemaining,
      });
      _subscription = updated;
    } else if (_subscription!.singleTickets >= 0 &&
        _subscription!.plan == SubscriptionPlan.single) {
      // 單次票 → 退回 1 張
      final updated = _subscription!.copyWith(
        singleTickets: _subscription!.singleTickets + 1,
      );
      await _firestore.collection('subscriptions').doc(userId).update({
        'singleTickets': updated.singleTickets,
      });
      _subscription = updated;
    }
    // 月票/季票 → 不受影響（本月內可再報名）

    notifyListeners();
  }

  /// 模擬購買（未來接 RevenueCat）
  Future<void> purchasePlan(String userId, SubscriptionPlan plan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      SubscriptionModel updated;

      switch (plan) {
        case SubscriptionPlan.single:
          updated = _subscription!.copyWith(
            plan: plan,
            singleTickets: _subscription!.singleTickets + 1,
            lastPurchaseAt: now,
          );
          break;
        case SubscriptionPlan.monthly:
          updated = _subscription!.copyWith(
            plan: plan,
            expiresAt: now.add(const Duration(days: 30)),
            lastPurchaseAt: now,
          );
          break;
        case SubscriptionPlan.quarterly:
          updated = _subscription!.copyWith(
            plan: plan,
            expiresAt: now.add(const Duration(days: 90)),
            lastPurchaseAt: now,
          );
          break;
        case SubscriptionPlan.free:
          return;
      }

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .update(updated.toMap());

      _subscription = updated;
    } catch (e) {
      debugPrint('[SubscriptionProvider] purchasePlan error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
