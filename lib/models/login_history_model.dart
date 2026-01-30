class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String device;
  final String location;
  final String ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.device,
    required this.location,
    required this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'device': device,
      'location': location,
      'ipAddress': ipAddress,
    };
  }

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      device: map['device'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown Location',
      ipAddress: map['ipAddress'] ?? 'Unknown IP',
    );
  }
}
