import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError, ValidationError } from '../utils/errors.js';
import { sendQuestionLink, sendReminder as sendSmsReminder } from '../mocks/sms.js';
import { sendQuestionLinkEmail } from '../mocks/email.js';
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
  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';
  const recordingUrl = `${appUrl}/record/${assignment.uniqueLinkToken}`;

  if (input.channel === 'sms') {
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

export async function sendReminder(
  userId: string,
  assignmentId: string,
  input: SendAssignmentInput
): Promise<{ message: string; reminder_count: number }> {
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

  const person = assignment.person;
  const owner = assignment.question.journal.owner;
  const questionText = assignment.question.questionText;
  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';
  const recordingUrl = `${appUrl}/record/${assignment.uniqueLinkToken}`;

  if (input.channel === 'sms') {
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

  const updated = await prisma.questionAssignment.update({
    where: { id: assignmentId },
    data: {
      reminderCount: { increment: 1 },
      lastReminderAt: new Date(),
    },
  });

  return {
    message: 'Reminder sent',
    reminder_count: updated.reminderCount,
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
