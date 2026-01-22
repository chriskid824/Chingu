import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Analytics Service
///
/// Responsible for tracking events and user interactions.
/// Currently logs events to the 'analytics_events' Firestore collection.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs a custom event.
  ///
  /// [name] The name of the event.
  /// [parameters] Optional parameters associated with the event.
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    try {
      final eventData = {
        'name': name,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        if (parameters != null) ...parameters,
      };

      await _firestore.collection('analytics_events').add(eventData);
      debugPrint('Analytics Event Logged: $name, params: $parameters');
    } catch (e) {
      debugPrint('Failed to log analytics event: $e');
    }
  }
}
