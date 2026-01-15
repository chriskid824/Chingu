import * as crypto from 'crypto';

export enum ExperimentGroup {
  Control = 'control',
  Variant = 'variant',
}

export enum NotificationType {
  Match = 'match',
  Message = 'message',
  Event = 'event',
  Rating = 'rating',
  System = 'system',
}

export interface NotificationContent {
  title: string;
  body: string;
}

/**
 * Assigns a user to an experiment group based on their user ID.
 * This uses a deterministic hash so the user always stays in the same group.
 */
export function getGroup(userId: string): ExperimentGroup {
  const hash = crypto.createHash('md5').update(userId).digest('hex');
  // Use first byte to determine group to ensure roughly 50/50 split
  const byte = parseInt(hash.substring(0, 2), 16);
  return byte % 2 === 0 ? ExperimentGroup.Control : ExperimentGroup.Variant;
}

/**
 * Returns the notification content (title and body) for a given user and notification type.
 *
 * @param userId The ID of the user receiving the notification.
 * @param type The type of notification.
 * @param params Optional parameters for dynamic content (e.g., 'partnerName', 'senderName', 'daysLeft').
 */
export function getNotificationContent(
  userId: string,
  type: NotificationType,
  params: Record<string, any> = {}
): NotificationContent {
  const group = getGroup(userId);
  const isVariant = group === ExperimentGroup.Variant;

  switch (type) {
    case NotificationType.Match:
      const partnerName = params.partnerName || 'Someone';
      if (isVariant) {
        return {
          title: 'New Match! 🎉',
          body: `You matched with ${partnerName}! Say hi now! 👋`,
        };
      } else {
        return {
          title: 'New Match',
          body: `You have a new match with ${partnerName}.`,
        };
      }

    case NotificationType.Message:
      const senderName = params.senderName || 'Someone';
      if (isVariant) {
        return {
          title: 'New Message 💬',
          body: `${senderName} sent you a message. Don't leave them waiting!`,
        };
      } else {
        return {
          title: 'New Message',
          body: `${senderName} sent you a message.`,
        };
      }

    case NotificationType.Event:
      const daysLeft = params.daysLeft;
      const eventTitle = params.eventTitle || 'Event';

      if (daysLeft !== undefined && daysLeft !== null) {
        if (isVariant) {
          return {
            title: 'Event Reminder 🍽️',
            body: `Get ready! "${eventTitle}" is in ${daysLeft} days! 😋`,
          };
        } else {
          return {
            title: 'Event Reminder',
            body: `You have an upcoming event "${eventTitle}" in ${daysLeft} days.`,
          };
        }
      }

      // Default event message
      if (isVariant) {
        return {
          title: 'Event Update 📅',
          body: `Check out the latest updates for your event "${eventTitle}".`,
        };
      } else {
        return {
          title: 'Event Update',
          body: `There is an update for your event "${eventTitle}".`,
        };
      }

    case NotificationType.Rating:
      if (isVariant) {
        return {
          title: 'How was it? ⭐',
          body: 'Rate your experience to help us improve! 📝',
        };
      } else {
        return {
          title: 'Rate your experience',
          body: 'Please rate your recent experience.',
        };
      }

    case NotificationType.System:
    default:
      const message = params.message || 'You have a new notification.';
      return {
        title: 'System Notification',
        body: message,
      };
  }
}
