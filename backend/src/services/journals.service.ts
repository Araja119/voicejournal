import { v4 as uuidv4 } from 'uuid';
import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError } from '../utils/errors.js';
import { uploadJournalCover } from '../mocks/storage.js';
import type {
  CreateJournalInput,
  UpdateJournalInput,
  AddCollaboratorInput,
  JournalQueryInput,
} from '../validators/journals.validators.js';

export interface JournalSummary {
  id: string;
  title: string;
  description: string | null;
  cover_image_url: string | null;
  privacy_setting: string;
  owner: {
    id: string;
    display_name: string;
  };
  dedicated_to_person: {
    id: string;
    name: string;
    relationship: string;
    profile_photo_url: string | null;
    linked_user_id: string | null;
  } | null;
  is_owner: boolean;
  question_count: number;
  answered_count: number;
  person_count: number;
  created_at: Date;
}

export interface JournalDetail extends JournalSummary {
  share_code: string | null;
  share_link: string | null;
  people: Array<{
    id: string;
    name: string;
    relationship: string;
    profile_photo_url: string | null;
  }>;
  questions: Array<{
    id: string;
    question_text: string;
    source: string;
    display_order: number;
    assignments: Array<{
      id: string;
      person_id: string;
      person_name: string;
      status: string;
      recording: {
        id: string;
        duration_seconds: number | null;
        recorded_at: Date | null;
      } | null;
    }>;
  }>;
}

function generateShareCode(): string {
  return uuidv4().replace(/-/g, '').substring(0, 12);
}

export async function listJournals(userId: string, query: JournalQueryInput): Promise<JournalSummary[]> {
  const whereConditions = [];

  if (query.owned) {
    whereConditions.push({ ownerId: userId });
  }

  if (query.shared) {
    whereConditions.push({
      collaborators: {
        some: { userId },
      },
    });
  }

  // If neither owned nor shared specified, get both
  if (!query.owned && !query.shared) {
    whereConditions.push({ ownerId: userId });
    whereConditions.push({
      collaborators: {
        some: { userId },
      },
    });
  }

  const journals = await prisma.journal.findMany({
    where: { OR: whereConditions },
    include: {
      owner: true,
      dedicatedToPerson: true,
      questions: {
        include: {
          assignments: {
            include: {
              person: true,
              recordings: true,
            },
          },
        },
      },
    },
    orderBy: { updatedAt: 'desc' },
  });

  return journals.map((journal) => {
    const answeredCount = journal.questions.reduce((count, q) => {
      return count + q.assignments.filter((a) => a.status === 'answered').length;
    }, 0);

    const uniquePersonIds = new Set<string>();
    journal.questions.forEach((q) => {
      q.assignments.forEach((a) => {
        uniquePersonIds.add(a.personId);
      });
    });

    return {
      id: journal.id,
      title: journal.title,
      description: journal.description,
      cover_image_url: journal.coverImageUrl,
      privacy_setting: journal.privacySetting,
      owner: {
        id: journal.owner.id,
        display_name: journal.owner.displayName,
      },
      dedicated_to_person: journal.dedicatedToPerson ? {
        id: journal.dedicatedToPerson.id,
        name: journal.dedicatedToPerson.name,
        relationship: journal.dedicatedToPerson.relationship,
        profile_photo_url: journal.dedicatedToPerson.profilePhotoUrl,
        linked_user_id: journal.dedicatedToPerson.linkedUserId,
      } : null,
      is_owner: journal.ownerId === userId,
      question_count: journal.questions.length,
      answered_count: answeredCount,
      person_count: uniquePersonIds.size,
      created_at: journal.createdAt,
    };
  });
}

export async function createJournal(userId: string, input: CreateJournalInput): Promise<JournalDetail> {
  const shareCode = generateShareCode();
  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';

  const journal = await prisma.journal.create({
    data: {
      ownerId: userId,
      title: input.title,
      description: input.description,
      privacySetting: input.privacy_setting,
      dedicatedToPersonId: input.dedicated_to_person_id,
      shareCode,
    },
    include: {
      owner: true,
      dedicatedToPerson: true,
    },
  });

  return {
    id: journal.id,
    title: journal.title,
    description: journal.description,
    cover_image_url: journal.coverImageUrl,
    privacy_setting: journal.privacySetting,
    share_code: journal.shareCode,
    share_link: `${appUrl}/j/${journal.shareCode}`,
    owner: {
      id: journal.owner.id,
      display_name: journal.owner.displayName,
    },
    dedicated_to_person: journal.dedicatedToPerson ? {
      id: journal.dedicatedToPerson.id,
      name: journal.dedicatedToPerson.name,
      relationship: journal.dedicatedToPerson.relationship,
      profile_photo_url: journal.dedicatedToPerson.profilePhotoUrl,
      linked_user_id: journal.dedicatedToPerson.linkedUserId,
    } : null,
    is_owner: true,
    question_count: 0,
    answered_count: 0,
    person_count: 0,
    people: [],
    questions: [],
    created_at: journal.createdAt,
  };
}

export async function getJournal(userId: string, journalId: string): Promise<JournalDetail> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
    include: {
      owner: true,
      dedicatedToPerson: true,
      collaborators: {
        include: { user: true },
      },
      questions: {
        include: {
          assignments: {
            include: {
              person: true,
              recordings: true,
            },
          },
        },
        orderBy: { displayOrder: 'asc' },
      },
    },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  // Check access
  const isOwner = journal.ownerId === userId;
  const isCollaborator = journal.collaborators.some((c) => c.userId === userId);

  if (!isOwner && !isCollaborator && journal.privacySetting === 'private') {
    throw new ForbiddenError('You do not have access to this journal');
  }

  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';

  // Get unique people
  const peopleMap = new Map<string, { id: string; name: string; relationship: string; profile_photo_url: string | null }>();
  journal.questions.forEach((q) => {
    q.assignments.forEach((a) => {
      if (!peopleMap.has(a.person.id)) {
        peopleMap.set(a.person.id, {
          id: a.person.id,
          name: a.person.name,
          relationship: a.person.relationship,
          profile_photo_url: a.person.profilePhotoUrl,
        });
      }
    });
  });

  const answeredCount = journal.questions.reduce((count, q) => {
    return count + q.assignments.filter((a) => a.status === 'answered').length;
  }, 0);

  return {
    id: journal.id,
    title: journal.title,
    description: journal.description,
    cover_image_url: journal.coverImageUrl,
    privacy_setting: journal.privacySetting,
    share_code: journal.shareCode,
    share_link: journal.shareCode ? `${appUrl}/j/${journal.shareCode}` : null,
    owner: {
      id: journal.owner.id,
      display_name: journal.owner.displayName,
    },
    dedicated_to_person: journal.dedicatedToPerson ? {
      id: journal.dedicatedToPerson.id,
      name: journal.dedicatedToPerson.name,
      relationship: journal.dedicatedToPerson.relationship,
      profile_photo_url: journal.dedicatedToPerson.profilePhotoUrl,
      linked_user_id: journal.dedicatedToPerson.linkedUserId,
    } : null,
    is_owner: isOwner,
    question_count: journal.questions.length,
    answered_count: answeredCount,
    person_count: peopleMap.size,
    people: Array.from(peopleMap.values()),
    questions: journal.questions.map((q) => ({
      id: q.id,
      question_text: q.questionText,
      source: q.source,
      display_order: q.displayOrder,
      assignments: q.assignments.map((a) => ({
        id: a.id,
        person_id: a.personId,
        person_name: a.person.name,
        status: a.status,
        recording: a.recordings[0]
          ? {
              id: a.recordings[0].id,
              duration_seconds: a.recordings[0].durationSeconds,
              recorded_at: a.recordings[0].recordedAt,
            }
          : null,
      })),
    })),
    created_at: journal.createdAt,
  };
}

export async function updateJournal(
  userId: string,
  journalId: string,
  input: UpdateJournalInput
): Promise<JournalDetail> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can update this journal');
  }

  await prisma.journal.update({
    where: { id: journalId },
    data: {
      title: input.title,
      description: input.description,
      privacySetting: input.privacy_setting,
      dedicatedToPersonId: input.dedicated_to_person_id,
    },
  });

  return getJournal(userId, journalId);
}

export async function deleteJournal(userId: string, journalId: string): Promise<void> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can delete this journal');
  }

  await prisma.journal.delete({
    where: { id: journalId },
  });
}

export async function updateCoverImage(
  userId: string,
  journalId: string,
  buffer: Buffer,
  contentType: string
): Promise<{ cover_image_url: string }> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can update the cover image');
  }

  const result = await uploadJournalCover(buffer, journalId, contentType);

  await prisma.journal.update({
    where: { id: journalId },
    data: { coverImageUrl: result.url },
  });

  return { cover_image_url: result.url };
}

export async function listCollaborators(userId: string, journalId: string) {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
    include: {
      collaborators: {
        include: { user: true },
      },
    },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can view collaborators');
  }

  return {
    collaborators: journal.collaborators.map((c) => ({
      id: c.id,
      user: c.user
        ? {
            id: c.user.id,
            display_name: c.user.displayName,
            email: c.user.email,
          }
        : null,
      email: c.email,
      phone_number: c.phoneNumber,
      permission_level: c.permissionLevel,
      invited_at: c.invitedAt,
      accepted_at: c.acceptedAt,
    })),
  };
}

export async function addCollaborator(userId: string, journalId: string, input: AddCollaboratorInput) {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can add collaborators');
  }

  // Check if user exists by email
  let targetUserId: string | null = null;
  if (input.email) {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });
    if (user) {
      targetUserId = user.id;
    }
  }

  const collaborator = await prisma.journalCollaborator.create({
    data: {
      journalId,
      userId: targetUserId,
      email: input.email,
      phoneNumber: input.phone_number,
      permissionLevel: input.permission_level,
    },
    include: { user: true },
  });

  return {
    id: collaborator.id,
    email: collaborator.email,
    phone_number: collaborator.phoneNumber,
    permission_level: collaborator.permissionLevel,
    invited_at: collaborator.invitedAt,
  };
}

export async function removeCollaborator(
  userId: string,
  journalId: string,
  collaboratorId: string
): Promise<void> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('Only the owner can remove collaborators');
  }

  const collaborator = await prisma.journalCollaborator.findUnique({
    where: { id: collaboratorId },
  });

  if (!collaborator || collaborator.journalId !== journalId) {
    throw new NotFoundError('Collaborator');
  }

  await prisma.journalCollaborator.delete({
    where: { id: collaboratorId },
  });
}

export async function getJournalByShareCode(shareCode: string, userId?: string) {
  const journal = await prisma.journal.findUnique({
    where: { shareCode },
    include: {
      owner: true,
    },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  // For public journals, return basic info
  // For private/shared journals, check access
  if (journal.privacySetting === 'private') {
    if (!userId) {
      throw new ForbiddenError('This journal is private');
    }

    const isOwner = journal.ownerId === userId;
    const isCollaborator = await prisma.journalCollaborator.findFirst({
      where: { journalId: journal.id, userId },
    });

    if (!isOwner && !isCollaborator) {
      throw new ForbiddenError('You do not have access to this journal');
    }
  }

  return {
    id: journal.id,
    title: journal.title,
    description: journal.description,
    cover_image_url: journal.coverImageUrl,
    owner: {
      id: journal.owner.id,
      display_name: journal.owner.displayName,
    },
    privacy_setting: journal.privacySetting,
  };
}
