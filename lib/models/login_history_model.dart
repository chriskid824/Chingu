import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String ipAddress;
  final String device;
  final String location;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.ipAddress,
    required this.device,
    required this.location,
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'] ?? 'Unknown',
      device: data['device'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'device': device,
      'location': location,
    };
  }
}
