import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError, ValidationError } from '../utils/errors.js';
import { uploadAudio, getSignedUrl } from '../mocks/storage.js';
import { notifyRecordingReceived } from '../mocks/push.js';
import { sendRecordingReceivedEmail } from '../mocks/email.js';
import { getUserPushTokens } from './users.service.js';
import type { RecordingsQueryInput } from '../validators/recordings.validators.js';

export interface RecordingPageData {
  assignment_id: string;
  question_text: string;
  person_name: string;
  requester_name: string;
  journal_title: string;
  status: string;
  already_answered: boolean;
}

export interface RecordingSummary {
  id: string;
  question: {
    id: string;
    question_text: string;
  };
  person: {
    id: string;
    name: string;
  };
  journal: {
    id: string;
    title: string;
  };
  audio_url: string;
  duration_seconds: number | null;
  transcription: string | null;
  recorded_at: Date | null;
}

export interface RecordingDetail extends RecordingSummary {}

export async function getRecordingPageData(linkToken: string): Promise<RecordingPageData> {
  const assignment = await prisma.questionAssignment.findUnique({
    where: { uniqueLinkToken: linkToken },
    include: {
      question: {
        include: {
          journal: {
            include: { owner: true },
          },
        },
      },
      person: true,
      recordings: true,
    },
  });

  if (!assignment) {
    throw new NotFoundError('Recording link');
  }

  // Mark as viewed if not already
  if (!assignment.viewedAt) {
    await prisma.questionAssignment.update({
      where: { id: assignment.id },
      data: { viewedAt: new Date(), status: 'viewed' },
    });
  }

  return {
    assignment_id: assignment.id,
    question_text: assignment.question.questionText,
    person_name: assignment.person.name,
    requester_name: assignment.question.journal.owner.displayName,
    journal_title: assignment.question.journal.title,
    status: assignment.status,
    already_answered: assignment.status === 'answered' || assignment.recordings.length > 0,
  };
}

export async function uploadRecording(
  linkToken: string,
  buffer: Buffer,
  durationSeconds?: number
): Promise<{ message: string; recording_id: string; duration_seconds: number | null }> {
  const assignment = await prisma.questionAssignment.findUnique({
    where: { uniqueLinkToken: linkToken },
    include: {
      question: {
        include: {
          journal: {
            include: { owner: true },
          },
        },
      },
      person: true,
      recordings: true,
    },
  });

  if (!assignment) {
    throw new NotFoundError('Recording link');
  }

  if (assignment.status === 'answered' || assignment.recordings.length > 0) {
    throw new ValidationError('This question has already been answered');
  }

  // Upload file
  const result = await uploadAudio(
    buffer,
    assignment.question.journal.ownerId,
    assignment.question.journalId,
    assignment.id
  );

  // Create recording
  const recording = await prisma.recording.create({
    data: {
      assignmentId: assignment.id,
      personId: assignment.personId,
      audioFileUrl: result.url,
      durationSeconds: durationSeconds || null,
      fileSizeBytes: BigInt(result.size),
      recordedAt: new Date(),
    },
  });

  // Update assignment status
  await prisma.questionAssignment.update({
    where: { id: assignment.id },
    data: {
      status: 'answered',
      answeredAt: new Date(),
    },
  });

  // Notify the journal owner
  const owner = assignment.question.journal.owner;
  const tokens = await getUserPushTokens(owner.id);

  if (tokens.length > 0) {
    await notifyRecordingReceived(
      tokens,
      assignment.person.name,
      assignment.question.questionText,
      recording.id,
      assignment.question.journalId
    );
  }

  // Also send email notification
  if (owner.email) {
    await sendRecordingReceivedEmail(
      owner.email,
      owner.displayName,
      assignment.person.name,
      assignment.question.questionText
    );
  }

  // Create in-app notification
  await prisma.notification.create({
    data: {
      recipientUserId: owner.id,
      notificationType: 'recording_received',
      channel: 'push',
      title: `${assignment.person.name} answered your question!`,
      body: assignment.question.questionText,
      relatedAssignmentId: assignment.id,
      relatedRecordingId: recording.id,
    },
  });

  return {
    message: 'Recording uploaded successfully',
    recording_id: recording.id,
    duration_seconds: recording.durationSeconds,
  };
}

export async function listRecordings(
  userId: string,
  query: RecordingsQueryInput
): Promise<{ recordings: RecordingSummary[]; total: number; limit: number; offset: number }> {
  const limit = query.limit || 20;
  const offset = query.offset || 0;

  const whereConditions: any = {
    assignment: {
      question: {
        journal: {
          ownerId: userId,
        },
      },
    },
  };

  if (query.journal_id) {
    whereConditions.assignment.question.journalId = query.journal_id;
  }

  if (query.person_id) {
    whereConditions.personId = query.person_id;
  }

  const [recordings, total] = await Promise.all([
    prisma.recording.findMany({
      where: whereConditions,
      include: {
        assignment: {
          include: {
            question: {
              include: { journal: true },
            },
            person: true,
          },
        },
      },
      orderBy: { uploadedAt: 'desc' },
      take: limit,
      skip: offset,
    }),
    prisma.recording.count({ where: whereConditions }),
  ]);

  return {
    recordings: recordings.map((r) => ({
      id: r.id,
      question: {
        id: r.assignment.question.id,
        question_text: r.assignment.question.questionText,
      },
      person: {
        id: r.assignment.person.id,
        name: r.assignment.person.name,
      },
      journal: {
        id: r.assignment.question.journal.id,
        title: r.assignment.question.journal.title,
      },
      audio_url: getSignedUrl(r.audioFileUrl),
      duration_seconds: r.durationSeconds,
      transcription: r.transcription,
      recorded_at: r.recordedAt,
    })),
    total,
    limit,
    offset,
  };
}

export async function getRecording(userId: string, recordingId: string): Promise<RecordingDetail> {
  const recording = await prisma.recording.findUnique({
    where: { id: recordingId },
    include: {
      assignment: {
        include: {
          question: {
            include: { journal: true },
          },
          person: true,
        },
      },
    },
  });

  if (!recording) {
    throw new NotFoundError('Recording');
  }

  if (recording.assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this recording');
  }

  return {
    id: recording.id,
    question: {
      id: recording.assignment.question.id,
      question_text: recording.assignment.question.questionText,
    },
    person: {
      id: recording.assignment.person.id,
      name: recording.assignment.person.name,
    },
    journal: {
      id: recording.assignment.question.journal.id,
      title: recording.assignment.question.journal.title,
    },
    audio_url: getSignedUrl(recording.audioFileUrl),
    duration_seconds: recording.durationSeconds,
    transcription: recording.transcription,
    recorded_at: recording.recordedAt,
  };
}

export async function deleteRecording(userId: string, recordingId: string): Promise<void> {
  const recording = await prisma.recording.findUnique({
    where: { id: recordingId },
    include: {
      assignment: {
        include: {
          question: {
            include: { journal: true },
          },
        },
      },
    },
  });

  if (!recording) {
    throw new NotFoundError('Recording');
  }

  if (recording.assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this recording');
  }

  await prisma.recording.delete({
    where: { id: recordingId },
  });

  // Reset assignment status
  await prisma.questionAssignment.update({
    where: { id: recording.assignmentId },
    data: {
      status: 'sent',
      answeredAt: null,
    },
  });
}

export async function requestTranscription(
  userId: string,
  recordingId: string
): Promise<{ message: string; estimated_time_seconds: number }> {
  const recording = await prisma.recording.findUnique({
    where: { id: recordingId },
    include: {
      assignment: {
        include: {
          question: {
            include: { journal: true },
          },
        },
      },
    },
  });

  if (!recording) {
    throw new NotFoundError('Recording');
  }

  if (recording.assignment.question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this recording');
  }

  // In a real implementation, this would queue a transcription job
  console.log(`=== MOCK TRANSCRIPTION ===`);
  console.log(`Recording ID: ${recordingId}`);
  console.log(`Would queue transcription job for: ${recording.audioFileUrl}`);
  console.log(`==========================`);

  return {
    message: 'Transcription started',
    estimated_time_seconds: 30,
  };
}
