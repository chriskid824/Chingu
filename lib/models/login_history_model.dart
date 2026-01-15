import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime loginTime;
  final String location;
  final String deviceInfo;
  final String ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.loginTime,
    required this.location,
    required this.deviceInfo,
    required this.ipAddress,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      loginTime: (map['loginTime'] as Timestamp).toDate(),
      location: map['location'] ?? 'Unknown',
      deviceInfo: map['deviceInfo'] ?? 'Unknown',
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'loginTime': Timestamp.fromDate(loginTime),
      'location': location,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }
}
