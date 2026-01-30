import 'package:flutter/material.dart';

class InterestConstants {
  /// 興趣分類資料
  static const List<Map<String, dynamic>> categories = [
    {
      'name': '休閒娛樂',
      'interests': [
        {'name': '電影', 'icon': Icons.movie_rounded},
        {'name': '音樂', 'icon': Icons.music_note_rounded},
        {'name': '遊戲', 'icon': Icons.sports_esports_rounded},
        {'name': '閱讀', 'icon': Icons.book_rounded},
        {'name': '動漫', 'icon': Icons.tv_rounded},
        {'name': '桌遊', 'icon': Icons.extension_rounded},
      ]
    },
    {
      'name': '生活風格',
      'interests': [
        {'name': '美食', 'icon': Icons.restaurant_rounded},
        {'name': '旅遊', 'icon': Icons.flight_rounded},
        {'name': '咖啡', 'icon': Icons.local_cafe_rounded},
        {'name': '寵物', 'icon': Icons.pets_rounded},
        {'name': '烹飪', 'icon': Icons.kitchen_rounded},
        {'name': '品酒', 'icon': Icons.wine_bar_rounded},
        {'name': '購物', 'icon': Icons.shopping_bag_rounded},
      ]
    },
    {
      'name': '運動健身',
      'interests': [
        {'name': '籃球', 'icon': Icons.sports_basketball_rounded},
        {'name': '健身', 'icon': Icons.fitness_center_rounded},
        {'name': '跑步', 'icon': Icons.directions_run_rounded},
        {'name': '游泳', 'icon': Icons.pool_rounded},
        {'name': '瑜珈', 'icon': Icons.self_improvement_rounded},
        {'name': '爬山', 'icon': Icons.hiking_rounded},
        {'name': '羽球', 'icon': Icons.sports_tennis_rounded},
      ]
    },
    {
      'name': '藝術創意',
      'interests': [
        {'name': '攝影', 'icon': Icons.camera_alt_rounded},
        {'name': '繪畫', 'icon': Icons.palette_rounded},
        {'name': '設計', 'icon': Icons.design_services_rounded},
        {'name': '手作', 'icon': Icons.cut_rounded},
        {'name': '寫作', 'icon': Icons.edit_rounded},
      ]
    },
    {
      'name': '科技與知識',
      'interests': [
        {'name': '科技', 'icon': Icons.computer_rounded},
        {'name': '程式設計', 'icon': Icons.code_rounded},
        {'name': '投資理財', 'icon': Icons.trending_up_rounded},
        {'name': '語言學習', 'icon': Icons.language_rounded},
      ]
    },
  ];

  /// 興趣名稱對應 Topic ID (English)
  static const Map<String, String> interestToTopicMap = {
    '電影': 'movie',
    '音樂': 'music',
    '遊戲': 'gaming',
    '閱讀': 'reading',
    '動漫': 'anime',
    '桌遊': 'board_games',
    '美食': 'food',
    '旅遊': 'travel',
    '咖啡': 'coffee',
    '寵物': 'pets',
    '烹飪': 'cooking',
    '品酒': 'wine',
    '購物': 'shopping',
    '籃球': 'basketball',
    '健身': 'fitness',
    '跑步': 'running',
    '游泳': 'swimming',
    '瑜珈': 'yoga',
    '爬山': 'hiking',
    '羽球': 'badminton',
    '攝影': 'photography',
    '繪畫': 'painting',
    '設計': 'design',
    '手作': 'handcraft',
    '寫作': 'writing',
    '科技': 'technology',
    '程式設計': 'coding',
    '投資理財': 'investment',
    '語言學習': 'language',
  };

  /// 地區名稱對應 Topic ID
  static const Map<String, String> regionToTopicMap = {
    'taipei': 'region_taipei',
    'taichung': 'region_taichung',
    'kaohsiung': 'region_kaohsiung',
    '台北市': 'region_taipei',
    '台中市': 'region_taichung',
    '高雄市': 'region_kaohsiung',
  };

  /// 獲取所有興趣的列表
  static List<Map<String, dynamic>> getAllInterests() {
    return categories
        .expand((category) => category['interests'] as List<Map<String, dynamic>>)
        .toList();
  }

  /// 根據興趣名稱獲取 Topic ID
  static String? getTopicForInterest(String interestName) {
    return interestToTopicMap[interestName];
  }
}
