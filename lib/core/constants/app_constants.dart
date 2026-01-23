import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> regions = ['taipei', 'taichung', 'kaohsiung'];

  static const List<Map<String, dynamic>> interestCategories = [
    {
      'name': '休閒娛樂',
      'interests': [
        {'id': 'movie', 'name': '電影', 'icon': Icons.movie_rounded},
        {'id': 'music', 'name': '音樂', 'icon': Icons.music_note_rounded},
        {'id': 'game', 'name': '遊戲', 'icon': Icons.sports_esports_rounded},
        {'id': 'reading', 'name': '閱讀', 'icon': Icons.book_rounded},
        {'id': 'anime', 'name': '動漫', 'icon': Icons.tv_rounded},
        {'id': 'board_game', 'name': '桌遊', 'icon': Icons.extension_rounded},
      ]
    },
    {
      'name': '生活風格',
      'interests': [
        {'id': 'food', 'name': '美食', 'icon': Icons.restaurant_rounded},
        {'id': 'travel', 'name': '旅遊', 'icon': Icons.flight_rounded},
        {'id': 'coffee', 'name': '咖啡', 'icon': Icons.local_cafe_rounded},
        {'id': 'pet', 'name': '寵物', 'icon': Icons.pets_rounded},
        {'id': 'cooking', 'name': '烹飪', 'icon': Icons.kitchen_rounded},
        {'id': 'wine', 'name': '品酒', 'icon': Icons.wine_bar_rounded},
        {'id': 'shopping', 'name': '購物', 'icon': Icons.shopping_bag_rounded},
      ]
    },
    {
      'name': '運動健身',
      'interests': [
        {'id': 'basketball', 'name': '籃球', 'icon': Icons.sports_basketball_rounded},
        {'id': 'fitness', 'name': '健身', 'icon': Icons.fitness_center_rounded},
        {'id': 'running', 'name': '跑步', 'icon': Icons.directions_run_rounded},
        {'id': 'swimming', 'name': '游泳', 'icon': Icons.pool_rounded},
        {'id': 'yoga', 'name': '瑜珈', 'icon': Icons.self_improvement_rounded},
        {'id': 'hiking', 'name': '爬山', 'icon': Icons.hiking_rounded},
        {'id': 'badminton', 'name': '羽球', 'icon': Icons.sports_tennis_rounded},
      ]
    },
    {
      'name': '藝術創意',
      'interests': [
        {'id': 'photography', 'name': '攝影', 'icon': Icons.camera_alt_rounded},
        {'id': 'painting', 'name': '繪畫', 'icon': Icons.palette_rounded},
        {'id': 'design', 'name': '設計', 'icon': Icons.design_services_rounded},
        {'id': 'craft', 'name': '手作', 'icon': Icons.cut_rounded},
        {'id': 'writing', 'name': '寫作', 'icon': Icons.edit_rounded},
      ]
    },
    {
      'name': '科技與知識',
      'interests': [
        {'id': 'technology', 'name': '科技', 'icon': Icons.computer_rounded},
        {'id': 'coding', 'name': '程式設計', 'icon': Icons.code_rounded},
        {'id': 'investment', 'name': '投資理財', 'icon': Icons.trending_up_rounded},
        {'id': 'language', 'name': '語言學習', 'icon': Icons.language_rounded},
      ]
    },
  ];
}
