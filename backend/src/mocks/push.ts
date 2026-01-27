export interface PushNotification {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendPushNotification(
  notification: PushNotification
): Promise<{ success: boolean; messageId: string }> {
  console.log('=== MOCK PUSH NOTIFICATION ===');
  console.log(`Token: ${notification.token.substring(0, 20)}...`);
  console.log(`Title: ${notification.title}`);
  console.log(`Body: ${notification.body}`);
  if (notification.data) {
    console.log(`Data: ${JSON.stringify(notification.data)}`);
  }
  console.log('==============================');

  // Simulate network delay
  await new Promise((resolve) => setTimeout(resolve, 50));

  return {
    success: true,
    messageId: `mock-push-${Date.now()}`,
  };
}

export async function sendPushToUser(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; sent: number; failed: number }> {
  let sent = 0;
  let failed = 0;

  for (const token of tokens) {
    try {
      await sendPushNotification({ token, title, body, data });
      sent++;
    } catch {
      failed++;
    }
  }

  return { success: failed === 0, sent, failed };
}

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

export async function notifyJournalShared(
  tokens: string[],
  ownerName: string,
  journalTitle: string,
  journalId: string
): Promise<{ success: boolean; sent: number; failed: number }> {
  return sendPushToUser(
    tokens,
    `${ownerName} shared a journal with you`,
    journalTitle,
    {
      type: 'journal_shared',
      journalId,
    }
  );
}
