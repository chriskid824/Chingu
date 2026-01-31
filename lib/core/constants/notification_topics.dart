class NotificationTopics {
  // Region Topics
  static const List<String> regions = [
    'Taipei',
    'Taichung',
    'Kaohsiung',
  ];

  // Interest Categories - using English keys for topics, mapped to Chinese in UI
  static const List<String> interestCategories = [
    'Leisure', // 休閒娛樂
    'Lifestyle', // 生活風格
    'Sports', // 運動健身
    'Arts', // 藝術創意
    'Tech', // 科技與知識
  ];

  // Map for UI display
  static const Map<String, String> regionDisplayNames = {
    'Taipei': '台北',
    'Taichung': '台中',
    'Kaohsiung': '高雄',
  };

  static const Map<String, String> interestDisplayNames = {
    'Leisure': '休閒娛樂',
    'Lifestyle': '生活風格',
    'Sports': '運動健身',
    'Arts': '藝術創意',
    'Tech': '科技與知識',
  };
}
