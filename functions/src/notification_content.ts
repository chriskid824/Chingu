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
 * Calculates a stable hash code for a string (Java String.hashCode implementation).
 * s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
 */
function getHashCode(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

export function getExperimentGroup(userId: string): ExperimentGroup {
  const hash = getHashCode(userId);
  // even -> control, odd -> variant
  return hash % 2 === 0 ? ExperimentGroup.Control : ExperimentGroup.Variant;
}

export function getNotificationContent(
  userId: string,
  type: NotificationType,
  params: Record<string, any> = {}
): NotificationContent {
  const group = getExperimentGroup(userId);
  const isVariant = group === ExperimentGroup.Variant;

  switch (type) {
    case NotificationType.Match: {
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
    }

    case NotificationType.Message: {
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
    }

    case NotificationType.Event: {
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

      // Default event update
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
    }

    case NotificationType.Rating: {
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
    }

    case NotificationType.System:
    default: {
      const message = params.message || 'You have a new notification.';
      return {
        title: 'System Notification',
        body: message,
      };
    }
  }
}
