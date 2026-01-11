// Function to determine notification content based on A/B testing
// This file is intended to be used in a Cloud Functions environment

export interface NotificationContent {
  title: string;
  body: string;
}

// Define the two variants for the A/B test
const variants: Record<string, NotificationContent> = {
  A: {
    title: '有人喜歡你！',
    body: '快來看看是誰對你感興趣，別錯過認識新朋友的機會！',
  },
  B: {
    title: '你有一個新的愛慕者！',
    body: '有人剛剛對你按了喜歡，現在就去查看並開始聊天吧！',
  },
};

/**
 * Gets the notification content for a specific user based on A/B testing logic.
 * The logic uses a simple hash of the userId to deterministically assign a group.
 *
 * @param userId - The ID of the user receiving the notification.
 * @param type - The type of notification (currently only supports 'like').
 * @returns The notification content (title and body).
 */
export function getNotificationContent(userId: string, type: string): NotificationContent {
  // Default content in case of unknown type
  const defaultContent: NotificationContent = {
    title: '新通知',
    body: '您有一則新通知',
  };

  if (type === 'like') {
    // Determine group based on userId hash
    // We take the last character of the userId and check if it's even or odd (or use ASCII value)
    // Assuming userId is a string like a UUID or Firestore ID

    // Simple deterministic assignment:
    // Sum of char codes % 2
    const charCodeSum = userId.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const group = charCodeSum % 2 === 0 ? 'A' : 'B';

    return variants[group];
  }

  // Add more types here as needed in the future

  return defaultContent;
}

/**
 * Helper to log which variant was served for analytics purposes.
 * This function is a placeholder for actual analytics implementation.
 *
 * @param userId - The user ID
 * @param variant - The variant served ('A' or 'B')
 */
export function logVariantExposure(userId: string, variant: string): void {
  console.log(`[A/B Test] User ${userId} assigned to Variant ${variant}`);
  // In a real implementation, you would log this to BigQuery or Firebase Analytics
}
