import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendBroadcast } from './sendBroadcast';

admin.initializeApp();

export const broadcast = functions.https.onCall(sendBroadcast);
