import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/dinner_group_model.dart';

/// 首頁主活動卡片的 5 種狀態
enum HomeState {
  /// 未報名 — 沒有未來活動，也沒有待評價群組
  notSignedUp,

  /// 配對中 — 已報名但尚未分組（或群組狀態為 pending）
  matching,

  /// 部分解鎖 — 群組狀態為 info_revealed（飯友星座/產業/年齡段已揭曉）
  partialReveal,

  /// 完全解鎖 — 群組狀態為 location_revealed（餐廳已揭曉）
  fullReveal,

  /// 待評價 — 群組已完成但尚未全部評價
  pendingReview,
}

/// 根據 Provider 資料判斷首頁狀態
class HomeStateResolver {
  /// 判斷當前首頁應顯示的狀態
  ///
  /// [myEvents] — 用戶已報名的所有活動
  /// [myGroups] — 用戶參與的所有群組
  /// [userId] — 當前用戶 UID
  static HomeStateResult resolve({
    required List<DinnerEventModel> myEvents,
    required List<DinnerGroupModel> myGroups,
    required String userId,
  }) {
    final now = DateTime.now();

    // 找待評價群組（已完成但評價未完成）
    final pendingReviewGroup = myGroups.cast<DinnerGroupModel?>().firstWhere(
      (g) => g!.status == 'completed' && g.reviewStatus != 'completed',
      orElse: () => null,
    );

    if (pendingReviewGroup != null) {
      return HomeStateResult(
        state: HomeState.pendingReview,
        group: pendingReviewGroup,
      );
    }

    // 找當前活躍的群組（非 completed）
    final activeGroup = myGroups.cast<DinnerGroupModel?>().firstWhere(
      (g) => g!.status != 'completed',
      orElse: () => null,
    );

    if (activeGroup != null) {
      switch (activeGroup.status) {
        case 'location_revealed':
          return HomeStateResult(
            state: HomeState.fullReveal,
            group: activeGroup,
          );
        case 'info_revealed':
          return HomeStateResult(
            state: HomeState.partialReveal,
            group: activeGroup,
          );
        default:
          // pending — 已分組但尚未解鎖
          return HomeStateResult(
            state: HomeState.matching,
            group: activeGroup,
            event: _findFutureEvent(myEvents, now),
          );
      }
    }

    // 沒有活躍群組，檢查是否有未來活動（已報名但尚未分組）
    final futureEvent = _findFutureEvent(myEvents, now);
    if (futureEvent != null) {
      return HomeStateResult(
        state: HomeState.matching,
        event: futureEvent,
      );
    }

    // 什麼都沒有 → 未報名
    return HomeStateResult(state: HomeState.notSignedUp);
  }

  static DinnerEventModel? _findFutureEvent(
    List<DinnerEventModel> events,
    DateTime now,
  ) {
    try {
      return events.firstWhere((e) => e.eventDate.isAfter(now));
    } catch (_) {
      return null;
    }
  }
}

/// 狀態判斷結果，攜帶相關的 event / group 資料
class HomeStateResult {
  final HomeState state;
  final DinnerEventModel? event;
  final DinnerGroupModel? group;

  const HomeStateResult({
    required this.state,
    this.event,
    this.group,
  });
}
