import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String uid;
  final DateTime timestamp;
  final String deviceName;
  final String deviceOs;
  final String ipAddress;
  final String location;

  LoginHistoryModel({
    required this.id,
    required this.uid,
    required this.timestamp,
    required this.deviceName,
    required this.deviceOs,
    required this.ipAddress,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceName': deviceName,
      'deviceOs': deviceOs,
      'ipAddress': ipAddress,
      'location': location,
    };
  }

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      uid: map['uid'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deviceName: map['deviceName'] ?? '',
      deviceOs: map['deviceOs'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      location: map['location'] ?? '',
    );
  }
}
