/**
 * Email provider router.
 * Uses Resend when EMAIL_PROVIDER=resend, otherwise falls back to console mock.
 */

export type { EmailMessage } from '../mocks/email.js';

type EmailModule = typeof import('../mocks/email.js');

let _mod: EmailModule;

if (process.env.EMAIL_PROVIDER === 'resend') {
  _mod = await import('./resend-email.js');
} else {
  _mod = await import('../mocks/email.js');
}

export const sendEmail = _mod.sendEmail;
export const sendPasswordResetEmail = _mod.sendPasswordResetEmail;
export const sendQuestionLinkEmail = _mod.sendQuestionLinkEmail;
export const sendRecordingReceivedEmail = _mod.sendRecordingReceivedEmail;
