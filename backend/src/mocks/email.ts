export interface EmailMessage {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export async function sendEmail(message: EmailMessage): Promise<{ success: boolean; messageId: string }> {
  console.log('=== MOCK EMAIL ===');
  console.log(`To: ${message.to}`);
  console.log(`Subject: ${message.subject}`);
  console.log(`Body: ${message.text || message.html.substring(0, 200)}...`);
  console.log('==================');

  // Simulate network delay
  await new Promise((resolve) => setTimeout(resolve, 100));

  return {
    success: true,
    messageId: `mock-email-${Date.now()}`,
  };
}

export async function sendPasswordResetEmail(
  email: string,
  resetToken: string,
  displayName: string
): Promise<{ success: boolean; messageId: string }> {
  const resetUrl = `${process.env.WEB_APP_URL}/reset-password?token=${resetToken}`;

  return sendEmail({
    to: email,
    subject: 'Reset your VoiceJournal password',
    html: `
      <h1>Hi ${displayName},</h1>
      <p>You requested to reset your password. Click the link below:</p>
      <a href="${resetUrl}">${resetUrl}</a>
      <p>This link expires in 1 hour.</p>
      <p>If you didn't request this, please ignore this email.</p>
    `,
    text: `Hi ${displayName}, reset your password here: ${resetUrl}`,
  });
}

export async function sendQuestionLinkEmail(
  email: string,
  recipientName: string,
  senderName: string,
  questionText: string,
  recordingUrl: string
): Promise<{ success: boolean; messageId: string }> {
  return sendEmail({
    to: email,
    subject: `${senderName} has a question for you`,
    html: `
      <h1>Hi ${recipientName}!</h1>
      <p>${senderName} would like to ask you:</p>
      <blockquote style="font-style: italic; padding: 10px; background: #f5f5f5; border-left: 3px solid #333;">
        "${questionText}"
      </blockquote>
      <p>
        <a href="${recordingUrl}" style="display: inline-block; padding: 12px 24px; background: #007bff; color: white; text-decoration: none; border-radius: 4px;">
          Record Your Answer
        </a>
      </p>
      <p>Or copy this link: ${recordingUrl}</p>
    `,
    text: `Hi ${recipientName}! ${senderName} would like to ask you: "${questionText}". Record your answer here: ${recordingUrl}`,
  });
}

export async function sendRecordingReceivedEmail(
  email: string,
  userName: string,
  personName: string,
  questionText: string
): Promise<{ success: boolean; messageId: string }> {
  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';

  return sendEmail({
    to: email,
    subject: `${personName} answered your question!`,
    html: `
      <h1>Hi ${userName}!</h1>
      <p>${personName} just recorded an answer to:</p>
      <blockquote style="font-style: italic; padding: 10px; background: #f5f5f5; border-left: 3px solid #333;">
        "${questionText}"
      </blockquote>
      <p>
        <a href="${appUrl}" style="display: inline-block; padding: 12px 24px; background: #007bff; color: white; text-decoration: none; border-radius: 4px;">
          Listen Now
        </a>
      </p>
    `,
    text: `Hi ${userName}! ${personName} answered your question: "${questionText}". Open the app to listen.`,
  });
}
