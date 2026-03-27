import 'package:flutter/material.dart';

class InterestCategory {
  final String name;
  final List<Interest> interests;

  const InterestCategory({required this.name, required this.interests});
}

class Interest {
  final String id;
  final String name;
  final IconData icon;

  const Interest({required this.id, required this.name, required this.icon});
}

class InterestsConstants {
  static const List<InterestCategory> categories = [
    InterestCategory(
      name: '休閒娛樂',
      interests: [
        Interest(id: 'movie', name: '電影', icon: Icons.movie_rounded),
        Interest(id: 'music', name: '音樂', icon: Icons.music_note_rounded),
        Interest(id: 'game', name: '遊戲', icon: Icons.sports_esports_rounded),
        Interest(id: 'reading', name: '閱讀', icon: Icons.book_rounded),
        Interest(id: 'anime', name: '動漫', icon: Icons.tv_rounded),
        Interest(id: 'boardgame', name: '桌遊', icon: Icons.extension_rounded),
      ],
    ),
    InterestCategory(
      name: '生活風格',
      interests: [
        Interest(id: 'food', name: '美食', icon: Icons.restaurant_rounded),
        Interest(id: 'travel', name: '旅遊', icon: Icons.flight_rounded),
        Interest(id: 'coffee', name: '咖啡', icon: Icons.local_cafe_rounded),
        Interest(id: 'pet', name: '寵物', icon: Icons.pets_rounded),
        Interest(id: 'cooking', name: '烹飪', icon: Icons.kitchen_rounded),
        Interest(id: 'wine', name: '品酒', icon: Icons.wine_bar_rounded),
        Interest(id: 'shopping', name: '購物', icon: Icons.shopping_bag_rounded),
      ],
    ),
    InterestCategory(
      name: '運動健身',
      interests: [
        Interest(id: 'basketball', name: '籃球', icon: Icons.sports_basketball_rounded),
        Interest(id: 'fitness', name: '健身', icon: Icons.fitness_center_rounded),
        Interest(id: 'running', name: '跑步', icon: Icons.directions_run_rounded),
        Interest(id: 'swimming', name: '游泳', icon: Icons.pool_rounded),
        Interest(id: 'yoga', name: '瑜珈', icon: Icons.self_improvement_rounded),
        Interest(id: 'hiking', name: '爬山', icon: Icons.hiking_rounded),
        Interest(id: 'badminton', name: '羽球', icon: Icons.sports_tennis_rounded),
      ],
    ),
    InterestCategory(
      name: '藝術創意',
      interests: [
        Interest(id: 'photography', name: '攝影', icon: Icons.camera_alt_rounded),
        Interest(id: 'painting', name: '繪畫', icon: Icons.palette_rounded),
        Interest(id: 'design', name: '設計', icon: Icons.design_services_rounded),
        Interest(id: 'craft', name: '手作', icon: Icons.cut_rounded),
        Interest(id: 'writing', name: '寫作', icon: Icons.edit_rounded),
      ],
    ),
    InterestCategory(
      name: '科技與知識',
      interests: [
        Interest(id: 'tech', name: '科技', icon: Icons.computer_rounded),
        Interest(id: 'coding', name: '程式設計', icon: Icons.code_rounded),
        Interest(id: 'investment', name: '投資理財', icon: Icons.trending_up_rounded),
        Interest(id: 'language', name: '語言學習', icon: Icons.language_rounded),
      ],
    ),
  ];

  static List<Interest> get allInterests {
    return categories
        .expand((category) => category.interests)
        .toList();
  }
}
