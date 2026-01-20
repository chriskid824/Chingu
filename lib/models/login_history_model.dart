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
    return LoginHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      device: data['device'] ?? 'Unknown Device',
      location: data['location'] ?? 'Unknown Location',
      ipAddress: data['ipAddress'],
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
