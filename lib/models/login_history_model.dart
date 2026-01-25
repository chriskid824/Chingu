import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String deviceName;
  final String osVersion;
  final String location;
  final String? ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.deviceName,
    required this.osVersion,
    required this.location,
    this.ipAddress,
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceName: data['deviceName'] ?? 'Unknown Device',
      osVersion: data['osVersion'] ?? 'Unknown OS',
      location: data['location'] ?? 'Unknown',
      ipAddress: data['ipAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceName': deviceName,
      'osVersion': osVersion,
      'location': location,
      'ipAddress': ipAddress,
    };
  }
}
