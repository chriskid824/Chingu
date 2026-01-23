import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime loginTime;
  final String location;
  final String device;
  final String? ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.loginTime,
    required this.location,
    required this.device,
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
      loginTime: (map['loginTime'] as Timestamp).toDate(),
      location: map['location'] ?? 'Unknown Location',
      device: map['device'] ?? 'Unknown Device',
      ipAddress: map['ipAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'loginTime': Timestamp.fromDate(loginTime),
      'location': location,
      'device': device,
      'ipAddress': ipAddress,
    };
  }
}
