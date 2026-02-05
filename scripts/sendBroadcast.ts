import * as admin from 'firebase-admin';

// Initialize Firebase Admin
// Make sure to set GOOGLE_APPLICATION_CREDENTIALS environment variable
// pointing to your service account key file.
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

/**
 * Sends a broadcast notification to all users subscribed to a specific topic
 * or via a multicast message to a list of tokens (less efficient for true broadcast).
 *
 * Recommended approach for "broadcast" is using FCM Topics (e.g., 'marketing' or 'all').
 */
async function sendBroadcast(
  title: string,
  body: string,
  topic: string = 'marketing',
  data?: { [key: string]: string }
) {
  const message: admin.messaging.Message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    topic: topic,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent broadcast to topic '${topic}':`, response);
  } catch (error) {
    console.error('Error sending broadcast:', error);
    process.exit(1);
  }
}

// Example usage checking for command line arguments
// Usage: ts-node sendBroadcast.ts <title> <body> [topic]
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.log('Usage: ts-node sendBroadcast.ts <title> <body> [topic]');
    process.exit(1);
  }

  const [title, body, topic] = args;
  sendBroadcast(title, body, topic || 'marketing');
}
