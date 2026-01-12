import * as admin from 'firebase-admin';

// Initialize the app once here if not doing it inside individual files,
// but it's safe to do check inside files too.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export * from './sendBroadcast';
