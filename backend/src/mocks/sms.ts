export interface SMSMessage {
  to: string;
  body: string;
}

export async function sendSMS(message: SMSMessage): Promise<{ success: boolean; messageId: string }> {
  console.log('=== MOCK SMS ===');
  console.log(`To: ${message.to}`);
  console.log(`Body: ${message.body}`);
  console.log('================');

  // Simulate network delay
  await new Promise((resolve) => setTimeout(resolve, 100));

  return {
    success: true,
    messageId: `mock-sms-${Date.now()}`,
  };
}

export async function sendQuestionLink(
  phoneNumber: string,
  recipientName: string,
  senderName: string,
  questionText: string,
  recordingUrl: string
): Promise<{ success: boolean; messageId: string }> {
  const body = `Hi ${recipientName}! ${senderName} would like to ask you: "${questionText.substring(0, 50)}${questionText.length > 50 ? '...' : ''}" Record your answer here: ${recordingUrl}`;

  return sendSMS({ to: phoneNumber, body });
}

export async function sendReminder(
  phoneNumber: string,
  recipientName: string,
  senderName: string,
  questionText: string,
  recordingUrl: string
): Promise<{ success: boolean; messageId: string }> {
  const body = `Reminder: ${senderName} is still waiting for your answer to: "${questionText.substring(0, 50)}${questionText.length > 50 ? '...' : ''}" Record here: ${recordingUrl}`;

  return sendSMS({ to: phoneNumber, body });
}
