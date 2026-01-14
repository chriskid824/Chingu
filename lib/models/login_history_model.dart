import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String deviceName;
  final String location;
  final String ipAddress;
  final String osVersion;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.deviceName,
    required this.location,
    required this.ipAddress,
    required this.osVersion,
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceName: data['deviceName'] ?? 'Unknown Device',
      location: data['location'] ?? 'Unknown Location',
      ipAddress: data['ipAddress'] ?? '',
      osVersion: data['osVersion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceName': deviceName,
      'location': location,
      'ipAddress': ipAddress,
      'osVersion': osVersion,
    };
  }
}
