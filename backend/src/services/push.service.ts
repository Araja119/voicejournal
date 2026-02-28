import admin from 'firebase-admin';
import prisma from '../utils/prisma.js';

let firebaseInitialized = false;

function initFirebase(): boolean {
  if (firebaseInitialized) return true;

  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccount) {
    return false;
  }

  try {
    let decoded: any;
    // Try base64 first, fall back to raw JSON
    try {
      decoded = JSON.parse(
        Buffer.from(serviceAccount, 'base64').toString('utf-8')
      );
    } catch {
      decoded = JSON.parse(serviceAccount);
    }
    admin.initializeApp({
      credential: admin.credential.cert(decoded),
      projectId: decoded.project_id,
    });
    firebaseInitialized = true;
    console.log('[Push] Firebase Admin SDK initialized');
    return true;
  } catch (err) {
    console.error('[Push] Failed to initialize Firebase:', err);
    return false;
  }
}

/**
 * Send a push notification to a single device token.
 * Returns null if Firebase is not configured (dev mode).
 */
async function sendPush(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<string | null> {
  if (!initFirebase()) return null;

  try {
    const messageId = await admin.messaging().send({
      token,
      notification: { title, body },
      data,
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    return messageId;
  } catch (err: any) {
    // Clean up invalid tokens
    if (
      err.code === 'messaging/invalid-registration-token' ||
      err.code === 'messaging/registration-token-not-registered'
    ) {
      console.log(`[Push] Removing invalid token: ${token.substring(0, 20)}...`);
      await prisma.pushToken.deleteMany({ where: { token } });
    } else {
      console.error(`[Push] Send failed:`, err.message || err);
    }
    return null;
  }
}

/**
 * Send a push notification to multiple device tokens.
 */
export async function sendPushToUser(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; sent: number; failed: number }> {
  if (!initFirebase()) {
    // Dev mode — log mock
    console.log(`=== MOCK PUSH === ${title}: ${body} (${tokens.length} tokens)`);
    return { success: true, sent: tokens.length, failed: 0 };
  }

  let sent = 0;
  let failed = 0;

  for (const token of tokens) {
    const result = await sendPush(token, title, body, data);
    if (result) sent++;
    else failed++;
  }

  return { success: failed === 0, sent, failed };
}

/**
 * Notify journal owner that someone recorded an answer.
 */
export async function notifyRecordingReceived(
  tokens: string[],
  personName: string,
  questionText: string,
  recordingId: string,
  journalId: string
): Promise<{ success: boolean; sent: number; failed: number }> {
  return sendPushToUser(
    tokens,
    `${personName} answered your question!`,
    `"${questionText.substring(0, 50)}${questionText.length > 50 ? '...' : ''}"`,
    {
      type: 'recording_received',
      recordingId,
      journalId,
    }
  );
}

/**
 * Notify person that they received a question.
 */
export async function notifyQuestionReceived(
  tokens: string[],
  senderName: string,
  questionText: string,
  assignmentId: string
): Promise<{ success: boolean; sent: number; failed: number }> {
  return sendPushToUser(
    tokens,
    `${senderName} has a question for you`,
    `"${questionText.substring(0, 50)}${questionText.length > 50 ? '...' : ''}"`,
    {
      type: 'question_received',
      assignmentId,
    }
  );
}
