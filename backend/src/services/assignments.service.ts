import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError, ValidationError } from '../utils/errors.js';
import { getAppUrl } from '../utils/url.js';
import { sendQuestionLink, sendReminder as sendSmsReminder } from '../mocks/sms.js';
import { sendQuestionLinkEmail } from './email.js';
import type { SendAssignmentInput } from '../validators/questions.validators.js';

export async function sendAssignment(
  userId: string,
  assignmentId: string,
  input: SendAssignmentInput
): Promise<{ message: string; sent_via: string; sent_at: Date }> {
  const assignment = await prisma.questionAssignment.findUnique({
    where: { id: assignmentId },
    include: {
      question: {
        include: {
          journal: {
            include: { owner: true },
          },
        },
      },
      person: true,
    },
  });

  if (!assignment) {
    throw new NotFoundError('Assignment');
  }

  if (assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this assignment');
  }

  const person = assignment.person;
  const owner = assignment.question.journal.owner;
  const questionText = assignment.question.questionText;
  const appUrl = getAppUrl();
  const recordingUrl = `${appUrl}/record/${assignment.uniqueLinkToken}`;

  if (input.channel === 'share') {
    // User shared via native share sheet — no delivery needed, just mark as sent
  } else if (input.channel === 'sms') {
    if (!person.phoneNumber) {
      throw new ValidationError('Person does not have a phone number');
    }

    await sendQuestionLink(
      person.phoneNumber,
      person.name,
      owner.displayName,
      questionText,
      recordingUrl
    );
  } else {
    if (!person.email) {
      throw new ValidationError('Person does not have an email address');
    }

    await sendQuestionLinkEmail(
      person.email,
      person.name,
      owner.displayName,
      questionText,
      recordingUrl
    );
  }

  const sentAt = new Date();

  await prisma.questionAssignment.update({
    where: { id: assignmentId },
    data: {
      status: 'sent',
      sentAt,
    },
  });

  return {
    message: 'Question sent successfully',
    sent_via: input.channel,
    sent_at: sentAt,
  };
}

// Escalating cooldown thresholds (in milliseconds)
const COOLDOWN_THRESHOLDS_MS = [
  24 * 60 * 60 * 1000,      // 24h after initial send (before 1st remind)
  72 * 60 * 60 * 1000,      // 72h after 1st remind (before 2nd)
  7 * 24 * 60 * 60 * 1000,  // 7 days after 2nd remind (before 3rd)
];

const MAX_REMINDERS_PER_QUESTION = 3;

function calculateNextEligibleAt(reminderCount: number, lastReminderAt: Date): Date | null {
  if (reminderCount >= MAX_REMINDERS_PER_QUESTION) return null;
  const thresholdIndex = Math.min(reminderCount, COOLDOWN_THRESHOLDS_MS.length - 1);
  const thresholdMs = COOLDOWN_THRESHOLDS_MS[thresholdIndex];
  return new Date(lastReminderAt.getTime() + thresholdMs);
}

export async function sendReminder(
  userId: string,
  assignmentId: string,
  input: SendAssignmentInput
): Promise<{ message: string; reminder_count: number; next_eligible_at: Date | null }> {
  const assignment = await prisma.questionAssignment.findUnique({
    where: { id: assignmentId },
    include: {
      question: {
        include: {
          journal: {
            include: { owner: true },
          },
        },
      },
      person: true,
    },
  });

  if (!assignment) {
    throw new NotFoundError('Assignment');
  }

  if (assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this assignment');
  }

  if (assignment.status === 'answered') {
    throw new ValidationError('This question has already been answered');
  }

  // Enforce per-question reminder cap
  if (assignment.reminderCount >= MAX_REMINDERS_PER_QUESTION) {
    throw new ValidationError('Maximum reminders reached for this question');
  }

  // Enforce escalating cooldown
  const lastAction = assignment.lastReminderAt || assignment.sentAt;
  if (lastAction) {
    const elapsed = Date.now() - lastAction.getTime();
    const thresholdIndex = Math.min(assignment.reminderCount, COOLDOWN_THRESHOLDS_MS.length - 1);
    const threshold = COOLDOWN_THRESHOLDS_MS[thresholdIndex];
    if (elapsed < threshold) {
      throw new ValidationError('Cooldown period has not elapsed');
    }
  }

  const person = assignment.person;
  const owner = assignment.question.journal.owner;
  const questionText = assignment.question.questionText;
  const appUrl = getAppUrl();
  const recordingUrl = `${appUrl}/record/${assignment.uniqueLinkToken}`;

  if (input.channel === 'share') {
    // User reminded via native share sheet — no delivery needed
  } else if (input.channel === 'sms') {
    if (!person.phoneNumber) {
      throw new ValidationError('Person does not have a phone number');
    }

    await sendSmsReminder(
      person.phoneNumber,
      person.name,
      owner.displayName,
      questionText,
      recordingUrl
    );
  } else {
    if (!person.email) {
      throw new ValidationError('Person does not have an email address');
    }

    await sendQuestionLinkEmail(
      person.email,
      person.name,
      owner.displayName,
      questionText,
      recordingUrl
    );
  }

  const now = new Date();
  const updated = await prisma.questionAssignment.update({
    where: { id: assignmentId },
    data: {
      reminderCount: { increment: 1 },
      lastReminderAt: now,
    },
  });

  return {
    message: 'Reminder sent',
    reminder_count: updated.reminderCount,
    next_eligible_at: calculateNextEligibleAt(updated.reminderCount, now),
  };
}

export async function deleteAssignment(userId: string, assignmentId: string): Promise<void> {
  const assignment = await prisma.questionAssignment.findUnique({
    where: { id: assignmentId },
    include: {
      question: {
        include: { journal: true },
      },
    },
  });

  if (!assignment) {
    throw new NotFoundError('Assignment');
  }

  if (assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this assignment');
  }

  await prisma.questionAssignment.delete({
    where: { id: assignmentId },
  });
}
