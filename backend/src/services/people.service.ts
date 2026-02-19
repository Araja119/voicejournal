import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError } from '../utils/errors.js';
import { uploadPersonPhoto, getSignedUrl } from './storage.js';

async function signPhotoUrl(url: string | null): Promise<string | null> {
  if (!url) return null;
  return getSignedUrl(url);
}
import type { CreatePersonInput, UpdatePersonInput } from '../validators/people.validators.js';

export interface PersonSummary {
  id: string;
  name: string;
  relationship: string;
  email: string | null;
  phone_number: string | null;
  profile_photo_url: string | null;
  total_recordings: number;
  pending_questions: number;
  created_at: Date;
}

export interface PersonDetail extends PersonSummary {
  recordings: Array<{
    id: string;
    question: {
      id: string;
      question_text: string;
    };
    journal: {
      id: string;
      title: string;
    };
    duration_seconds: number | null;
    recorded_at: Date | null;
  }>;
  pending_assignments: Array<{
    id: string;
    question: {
      id: string;
      question_text: string;
    };
    status: string;
    sent_at: Date | null;
  }>;
}

export async function listPeople(userId: string): Promise<PersonSummary[]> {
  const people = await prisma.person.findMany({
    where: { ownerId: userId },
    include: {
      recordings: true,
      assignments: {
        where: {
          status: { in: ['pending', 'sent', 'viewed'] },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return Promise.all(people.map(async (person) => ({
    id: person.id,
    name: person.name,
    relationship: person.relationship,
    email: person.email,
    phone_number: person.phoneNumber,
    profile_photo_url: await signPhotoUrl(person.profilePhotoUrl),
    total_recordings: person.recordings.length,
    pending_questions: person.assignments.length,
    created_at: person.createdAt,
  })));
}

export async function createPerson(userId: string, input: CreatePersonInput & { linked_user_id?: string }): Promise<PersonSummary> {
  let person = await prisma.person.create({
    data: {
      ownerId: userId,
      name: input.name,
      relationship: input.relationship,
      email: input.email || null,
      phoneNumber: input.phone_number || null,
      linkedUserId: input.linked_user_id || null,
    },
  });

  // Auto-sync profile photo from linked user for "self" persons
  if (person.relationship === 'self' && person.linkedUserId) {
    const linkedUser = await prisma.user.findUnique({
      where: { id: person.linkedUserId },
      select: { profilePhotoUrl: true },
    });
    if (linkedUser?.profilePhotoUrl) {
      person = await prisma.person.update({
        where: { id: person.id },
        data: { profilePhotoUrl: linkedUser.profilePhotoUrl },
      });
    }
  }

  return {
    id: person.id,
    name: person.name,
    relationship: person.relationship,
    email: person.email,
    phone_number: person.phoneNumber,
    profile_photo_url: await signPhotoUrl(person.profilePhotoUrl),
    total_recordings: 0,
    pending_questions: 0,
    created_at: person.createdAt,
  };
}

export async function getPerson(userId: string, personId: string): Promise<PersonDetail> {
  const person = await prisma.person.findUnique({
    where: { id: personId },
    include: {
      recordings: {
        include: {
          assignment: {
            include: {
              question: {
                include: {
                  journal: true,
                },
              },
            },
          },
        },
        orderBy: { uploadedAt: 'desc' },
      },
      assignments: {
        where: {
          status: { in: ['pending', 'sent', 'viewed'] },
        },
        include: {
          question: true,
        },
        orderBy: { sentAt: 'desc' },
      },
    },
  });

  if (!person) {
    throw new NotFoundError('Person');
  }

  if (person.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this person');
  }

  return {
    id: person.id,
    name: person.name,
    relationship: person.relationship,
    email: person.email,
    phone_number: person.phoneNumber,
    profile_photo_url: await signPhotoUrl(person.profilePhotoUrl),
    total_recordings: person.recordings.length,
    pending_questions: person.assignments.length,
    created_at: person.createdAt,
    recordings: person.recordings.map((r) => ({
      id: r.id,
      question: {
        id: r.assignment.question.id,
        question_text: r.assignment.question.questionText,
      },
      journal: {
        id: r.assignment.question.journal.id,
        title: r.assignment.question.journal.title,
      },
      duration_seconds: r.durationSeconds,
      recorded_at: r.recordedAt,
    })),
    pending_assignments: person.assignments.map((a) => ({
      id: a.id,
      question: {
        id: a.question.id,
        question_text: a.question.questionText,
      },
      status: a.status,
      sent_at: a.sentAt,
    })),
  };
}

export async function updatePerson(
  userId: string,
  personId: string,
  input: UpdatePersonInput
): Promise<PersonSummary> {
  const person = await prisma.person.findUnique({
    where: { id: personId },
  });

  if (!person) {
    throw new NotFoundError('Person');
  }

  if (person.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this person');
  }

  const updated = await prisma.person.update({
    where: { id: personId },
    data: {
      name: input.name,
      relationship: input.relationship,
      email: input.email === '' ? null : input.email,
      phoneNumber: input.phone_number,
    },
    include: {
      recordings: true,
      assignments: {
        where: {
          status: { in: ['pending', 'sent', 'viewed'] },
        },
      },
    },
  });

  return {
    id: updated.id,
    name: updated.name,
    relationship: updated.relationship,
    email: updated.email,
    phone_number: updated.phoneNumber,
    profile_photo_url: await signPhotoUrl(updated.profilePhotoUrl),
    total_recordings: updated.recordings.length,
    pending_questions: updated.assignments.length,
    created_at: updated.createdAt,
  };
}

export async function deletePerson(userId: string, personId: string): Promise<void> {
  const person = await prisma.person.findUnique({
    where: { id: personId },
  });

  if (!person) {
    throw new NotFoundError('Person');
  }

  if (person.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this person');
  }

  // Cascade delete all journals dedicated to this person
  const dedicatedJournals = await prisma.journal.findMany({
    where: { dedicatedToPersonId: personId, ownerId: userId },
  });

  for (const journal of dedicatedJournals) {
    // Delete questions (and their assignments/recordings) then the journal
    await prisma.journal.delete({
      where: { id: journal.id },
    });
  }

  await prisma.person.delete({
    where: { id: personId },
  });
}

export async function updatePersonPhoto(
  userId: string,
  personId: string,
  buffer: Buffer,
  contentType: string
): Promise<{ profile_photo_url: string }> {
  const person = await prisma.person.findUnique({
    where: { id: personId },
  });

  if (!person) {
    throw new NotFoundError('Person');
  }

  if (person.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this person');
  }

  const result = await uploadPersonPhoto(buffer, personId, contentType);

  await prisma.person.update({
    where: { id: personId },
    data: { profilePhotoUrl: result.url },
  });

  return { profile_photo_url: await getSignedUrl(result.url) };
}
