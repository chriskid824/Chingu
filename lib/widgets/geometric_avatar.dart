import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 抽象幾何頭像系統
///
/// 照片顯示規則：
/// - 見面前（週四 19:00 前）→ 一律顯示幾何頭像
/// - 週四 19:00 後 → 群組聊天內照片解鎖
/// - 一對一聊天（Match 後）→ 直接顯示真實照片
/// - 個人檔案/設定 → 顯示自己的真實照片
class GeometricAvatar extends StatelessWidget {
  /// 用來決定幾何圖形與顏色的種子（通常是 userId 或 index）
  final String seed;

  /// 真實照片 URL（null 時永遠顯示幾何頭像）
  final String? photoUrl;

  /// 是否允許顯示真實照片（由呼叫端根據時間軸規則決定）
  final bool showPhoto;

  /// 頭像尺寸
  final double size;

  /// 使用者名稱首字（fallback，當沒照片也不用幾何圖形時）
  final String? name;

  const GeometricAvatar({
    super.key,
    required this.seed,
    this.photoUrl,
    this.showPhoto = false,
    this.size = 44,
    this.name,
  });

  // 7 種莫蘭迪色調（公開供其他元件引用）
  static const colors = [
    Color(0xFF6B93B8), // 藍灰
    Color(0xFFD67756), // 磚橘
    Color(0xFF8DB6C9), // 淺藍
    Color(0xFFA64A25), // 深磚橘
    Color(0xFF7CAF7C), // 莫蘭迪綠
    Color(0xFF885520), // 棕色
    Color(0xFFB88A6B), // 駝色
  ];

  // 7 種幾何圖形（公開供其他元件引用）
  static const icons = [
    Icons.hexagon_rounded,
    Icons.change_history_rounded, // 三角
    Icons.circle_outlined,
    Icons.square_rounded,
    Icons.pentagon_rounded,
    Icons.star_rounded,
    Icons.diamond_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // 如果允許顯示照片且有照片 URL → 顯示真實照片
    if (showPhoto && photoUrl != null && photoUrl!.isNotEmpty) {
      return _buildPhotoAvatar();
    }

    // 否則顯示幾何頭像
    return _buildGeometricAvatar();
  }

  Widget _buildPhotoAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildGeometricAvatar(),
        errorWidget: (_, __, ___) => _buildGeometricAvatar(),
      ),
    );
  }

  Widget _buildGeometricAvatar() {
    final index = _seedToIndex(seed);
    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  /// 將 seed 字串轉為穩定的整數索引
  int _seedToIndex(String seed) {
    if (seed.isEmpty) return 0;
    var hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }
}

/// 照片顯示規則判斷工具
class PhotoVisibility {
  /// 群組聊天：週四 19:00 後照片解鎖
  static bool isGroupPhotoUnlocked(DateTime eventDate) {
    // 照片解鎖時間 = 活動當天 19:00
    final unlockTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      19,
      0,
    );
    return DateTime.now().isAfter(unlockTime);
  }

  /// 一對一聊天：Match 後直接顯示
  static bool isDirectChatPhotoVisible() => true;

  /// 個人檔案：自己的照片永遠可見
  static bool isSelfPhotoVisible() => true;

  /// 評價頁面：晚餐後（群組 completed）照片已解鎖
  static bool isReviewPhotoVisible() => true;
}
