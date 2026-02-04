import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM_EMAIL = process.env.EMAIL_FROM || 'VoiceJournal <noreply@voicejournal.app>';

export interface EmailMessage {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export async function sendEmail(message: EmailMessage): Promise<{ success: boolean; messageId: string }> {
  try {
    const { data, error } = await resend.emails.send({
      from: FROM_EMAIL,
      to: message.to,
      subject: message.subject,
      html: message.html,
      text: message.text,
    });

    if (error) {
      console.error('Resend error:', error);
      return { success: false, messageId: '' };
    }

    return { success: true, messageId: data?.id || '' };
  } catch (err) {
    console.error('Resend send failed:', err);
    return { success: false, messageId: '' };
  }
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
