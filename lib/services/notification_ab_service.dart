/// Notification A/B Testing Service
///
/// This service is responsible for assigning users to experimental groups (A/B testing)
/// and serving varied notification content based on the assigned group.
///
/// The current implementation uses a deterministic hash of the user ID to assign groups.

import 'package:cloud_firestore/cloud_firestore.dart';

enum ExperimentGroup {
  control, // Group A (Default)
  variant, // Group B (Experimental)
}

enum NotificationType {
  match,
  message,
  event,
  rating,
  system,
}

class NotificationContent {
  final String title;
  final String body;

  NotificationContent({required this.title, required this.body});
}

class NotificationABService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Assigns a user to an experiment group based on their user ID.
  ///
  /// This uses a deterministic hash so the user always stays in the same group.
  ExperimentGroup getGroup(String userId) {
    // Simple deterministic hash: even hash -> control, odd hash -> variant
    final hash = userId.hashCode;
    return hash % 2 == 0 ? ExperimentGroup.control : ExperimentGroup.variant;
  }

  /// Returns the notification content (title and body) for a given user and notification type.
  ///
  /// [userId] The ID of the user receiving the notification.
  /// [type] The type of notification.
  /// [params] Optional parameters for dynamic content (e.g., 'partnerName', 'senderName', 'daysLeft').
  NotificationContent getContent(
    String userId,
    NotificationType type,
    {Map<String, dynamic>? params}
  ) {
    final group = getGroup(userId);
    final isVariant = group == ExperimentGroup.variant;

    switch (type) {
      case NotificationType.match:
        final partnerName = params?['partnerName'] ?? 'Someone';
        if (isVariant) {
          return NotificationContent(
            title: 'New Match! 🎉',
            body: 'You matched with $partnerName! Say hi now! 👋',
          );
        } else {
          return NotificationContent(
            title: 'New Match',
            body: 'You have a new match with $partnerName.',
          );
        }

      case NotificationType.message:
        final senderName = params?['senderName'] ?? 'Someone';
        if (isVariant) {
          return NotificationContent(
            title: 'New Message 💬',
            body: '$senderName sent you a message. Don\'t leave them waiting!',
          );
        } else {
          return NotificationContent(
            title: 'New Message',
            body: '$senderName sent you a message.',
          );
        }

      case NotificationType.event:
        final daysLeft = params?['daysLeft'];
        final eventTitle = params?['eventTitle'] ?? 'Event';

        if (daysLeft != null) {
           if (isVariant) {
             return NotificationContent(
               title: 'Event Reminder 🍽️',
               body: 'Get ready! "$eventTitle" is in $daysLeft days! 😋',
             );
           } else {
             return NotificationContent(
               title: 'Event Reminder',
               body: 'You have an upcoming event "$eventTitle" in $daysLeft days.',
             );
           }
        }

        // Default event message
        if (isVariant) {
           return NotificationContent(
             title: 'Event Update 📅',
             body: 'Check out the latest updates for your event "$eventTitle".',
           );
        } else {
           return NotificationContent(
             title: 'Event Update',
             body: 'There is an update for your event "$eventTitle".',
           );
        }

      case NotificationType.rating:
         if (isVariant) {
           return NotificationContent(
             title: 'How was it? ⭐',
             body: 'Rate your experience to help us improve! 📝',
           );
         } else {
           return NotificationContent(
             title: 'Rate your experience',
             body: 'Please rate your recent experience.',
           );
         }

      case NotificationType.system:
      default:
        // System notifications might not vary much, but we keep the structure consistent
        final message = params?['message'] ?? 'You have a new notification.';
        return NotificationContent(
          title: 'System Notification',
          body: message,
        );
    }
  }

  /// Tracks notification events (sent/clicked) for A/B testing analysis.
  Future<void> trackEvent({
    required String userId,
    required String notificationId,
    required String type,
    required ExperimentGroup group,
    required String event,
  }) async {
    try {
      await _firestore.collection('notification_analytics').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type,
        'group': group.name,
        'event': event, // 'sent' or 'clicked'
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silently or log error, but don't crash the app
      print('Error tracking notification event: $e');
    }
  }
}
