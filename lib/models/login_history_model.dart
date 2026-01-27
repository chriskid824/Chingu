import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String device;
  final String location;
  final String? ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.device,
    required this.location,
    this.ipAddress,
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel.fromMap(data, doc.id);
  }

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      device: map['device'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown Location',
      ipAddress: map['ipAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'device': device,
      'location': location,
      'ipAddress': ipAddress,
    };
  }
}
