/// 活動模板模型 (地點、時間、主題模板)
class EventTemplateModel {
  final String id;
  final String city;
  final String district;
  final String restaurantName;
  final String theme; // e.g., 'Foodie', 'Tech', 'Casual'
  final List<String> icebreakerQuestions;

  EventTemplateModel({
    required this.id,
    required this.city,
    required this.district,
    required this.restaurantName,
    required this.theme,
    required this.icebreakerQuestions,
  });

  // This would typically be fetched from Firestore 'event_templates' collection
}
