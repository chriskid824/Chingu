import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String deviceInfo;
  final String location;
  final String ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.deviceInfo,
    this.location = 'Unknown',
    this.ipAddress = 'Unknown',
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceInfo: data['deviceInfo'] ?? 'Unknown Device',
      location: data['location'] ?? 'Unknown',
      ipAddress: data['ipAddress'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceInfo': deviceInfo,
      'location': location,
      'ipAddress': ipAddress,
    };
  }
}
