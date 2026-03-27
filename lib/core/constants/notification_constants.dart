class NotificationConstants {
  static const String topicPrefixRegion = 'topic_region_';
  static const String topicPrefixInterest = 'topic_interest_';

  // Region topics
  static const String topicRegionTaipei = 'topic_region_taipei';
  static const String topicRegionTaichung = 'topic_region_taichung';
  static const String topicRegionKaohsiung = 'topic_region_kaohsiung';

  static const Map<String, String> regionTopics = {
    '台北': topicRegionTaipei,
    '台中': topicRegionTaichung,
    '高雄': topicRegionKaohsiung,
  };

  static String getTopicForInterest(String interestId) {
     return '$topicPrefixInterest$interestId';
  }
}
