/// Notification Topic Constants
class NotificationTopics {
  // Available Regions
  static const String regionTaipei = 'Taipei';
  static const String regionTaichung = 'Taichung';
  static const String regionKaohsiung = 'Kaohsiung';

  static const List<String> availableRegions = [
    regionTaipei,
    regionTaichung,
    regionKaohsiung,
  ];

  // Available Interests/Topics
  static const String topicFood = 'Food';
  static const String topicTech = 'Tech';
  static const String topicArt = 'Art';
  static const String topicMusic = 'Music';
  static const String topicTravel = 'Travel';

  static const List<String> availableTopics = [
    topicFood,
    topicTech,
    topicArt,
    topicMusic,
    topicTravel,
  ];

  /// Get FCM topic ID for a region
  /// Example: 'Taipei' -> 'region_taipei'
  static String getRegionTopicId(String regionName) {
    return 'region_${regionName.toLowerCase()}';
  }

  /// Get FCM topic ID for an interest
  /// Example: 'Food' -> 'topic_food'
  static String getInterestTopicId(String topicName) {
    return 'topic_${topicName.toLowerCase()}';
  }

  /// Display names for UI (Optional, if we want Chinese)
  static Map<String, String> regionDisplayNames = {
    regionTaipei: '台北',
    regionTaichung: '台中',
    regionKaohsiung: '高雄',
  };

  static Map<String, String> topicDisplayNames = {
    topicFood: '美食',
    topicTech: '科技',
    topicArt: '藝術',
    topicMusic: '音樂',
    topicTravel: '旅遊',
  };
}
