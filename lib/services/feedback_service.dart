import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitFeedback({
    required FeedbackType type,
    required String content,
    String? contactEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit feedback');
      }

      // Get app version
      String appVersion = 'Unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        // Ignore package info error
      }

      // Get basic device info
      Map<String, dynamic> deviceInfo = {
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
      };

      final docRef = _firestore.collection('feedback').doc();

      final feedback = FeedbackModel(
        id: docRef.id,
        userId: user.uid,
        type: type,
        content: content,
        createdAt: DateTime.now(),
        contactEmail: contactEmail,
        status: FeedbackStatus.pending,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
      );

      await docRef.set(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
