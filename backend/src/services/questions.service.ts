import { v4 as uuidv4 } from 'uuid';
import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError, ValidationError } from '../utils/errors.js';
import type {
  CreateQuestionInput,
  BulkCreateQuestionsInput,
  UpdateQuestionInput,
  ReorderQuestionsInput,
  AssignQuestionInput,
} from '../validators/questions.validators.js';

function generateLinkToken(): string {
  return uuidv4().replace(/-/g, '') + uuidv4().replace(/-/g, '').substring(0, 8);
}

export interface QuestionWithAssignments {
  id: string;
  question_text: string;
  source: string;
  display_order: number;
  assignments: Array<{
    id: string;
    person_id: string;
    status: string;
  }>;
}

export interface AssignmentWithLink {
  id: string;
  question_id: string;
  person_id: string;
  status: string;
  unique_link_token: string;
  recording_link: string;
}

async function verifyJournalOwnership(userId: string, journalId: string): Promise<void> {
  const journal = await prisma.journal.findUnique({
    where: { id: journalId },
  });

  if (!journal) {
    throw new NotFoundError('Journal');
  }

  if (journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this journal');
  }
}

export async function createQuestion(
  userId: string,
  journalId: string,
  input: CreateQuestionInput
): Promise<QuestionWithAssignments> {
  await verifyJournalOwnership(userId, journalId);

  // Get current max display order
  const maxOrder = await prisma.question.aggregate({
    where: { journalId },
    _max: { displayOrder: true },
  });

  const displayOrder = (maxOrder._max.displayOrder ?? -1) + 1;

  const question = await prisma.question.create({
    data: {
      journalId,
      questionText: input.question_text,
      source: input.template_id ? 'template' : 'custom',
      templateId: input.template_id,
      displayOrder,
    },
  });

  // Create assignments if person IDs provided
  const assignments: Array<{ id: string; person_id: string; status: string }> = [];

  if (input.assign_to_person_ids && input.assign_to_person_ids.length > 0) {
    for (const personId of input.assign_to_person_ids) {
      // Verify person belongs to user
      const person = await prisma.person.findUnique({
        where: { id: personId },
      });

      if (!person || person.ownerId !== userId) {
        continue;
      }

      const assignment = await prisma.questionAssignment.create({
        data: {
          questionId: question.id,
          personId,
          uniqueLinkToken: generateLinkToken(),
        },
      });

      assignments.push({
        id: assignment.id,
        person_id: assignment.personId,
        status: assignment.status,
      });
    }
  }

  return {
    id: question.id,
    question_text: question.questionText,
    source: question.source,
    display_order: question.displayOrder,
    assignments,
  };
}

export async function bulkCreateQuestions(
  userId: string,
  journalId: string,
  input: BulkCreateQuestionsInput
): Promise<{ questions: QuestionWithAssignments[] }> {
  await verifyJournalOwnership(userId, journalId);

  const questions: QuestionWithAssignments[] = [];

  for (const q of input.questions) {
    const question = await createQuestion(userId, journalId, {
      question_text: q.question_text,
      template_id: q.template_id,
      assign_to_person_ids: input.assign_to_person_ids,
    });
    questions.push(question);
  }

  return { questions };
}

export async function updateQuestion(
  userId: string,
  journalId: string,
  questionId: string,
  input: UpdateQuestionInput
): Promise<QuestionWithAssignments> {
  await verifyJournalOwnership(userId, journalId);

  const question = await prisma.question.findUnique({
    where: { id: questionId },
    include: { assignments: true },
  });

  if (!question || question.journalId !== journalId) {
    throw new NotFoundError('Question');
  }

  const updated = await prisma.question.update({
    where: { id: questionId },
    data: {
      questionText: input.question_text,
      displayOrder: input.display_order,
    },
    include: { assignments: true },
  });

  return {
    id: updated.id,
    question_text: updated.questionText,
    source: updated.source,
    display_order: updated.displayOrder,
    assignments: updated.assignments.map((a) => ({
      id: a.id,
      person_id: a.personId,
      status: a.status,
    })),
  };
}

export async function deleteQuestion(
  userId: string,
  journalId: string,
  questionId: string
): Promise<void> {
  await verifyJournalOwnership(userId, journalId);

  const question = await prisma.question.findUnique({
    where: { id: questionId },
  });

  if (!question || question.journalId !== journalId) {
    throw new NotFoundError('Question');
  }

  await prisma.question.delete({
    where: { id: questionId },
  });
}

export async function reorderQuestions(
  userId: string,
  journalId: string,
  input: ReorderQuestionsInput
): Promise<void> {
  await verifyJournalOwnership(userId, journalId);

  // Verify all questions belong to this journal
  const questions = await prisma.question.findMany({
    where: {
      id: { in: input.question_ids },
      journalId,
    },
  });

  if (questions.length !== input.question_ids.length) {
    throw new ValidationError('Some question IDs are invalid or do not belong to this journal');
  }

  // Update display orders
  await prisma.$transaction(
    input.question_ids.map((id, index) =>
      prisma.question.update({
        where: { id },
        data: { displayOrder: index },
      })
    )
  );
}

export async function assignQuestion(
  userId: string,
  questionId: string,
  input: AssignQuestionInput
): Promise<{ assignments: AssignmentWithLink[] }> {
  const question = await prisma.question.findUnique({
    where: { id: questionId },
    include: { journal: true },
  });

  if (!question) {
    throw new NotFoundError('Question');
  }

  if (question.journal.ownerId !== userId) {
    throw new ForbiddenError('You do not have access to this question');
  }

  const appUrl = process.env.WEB_APP_URL || 'http://localhost:3000';
  const assignments: AssignmentWithLink[] = [];

  for (const personId of input.person_ids) {
    // Verify person belongs to user
    const person = await prisma.person.findUnique({
      where: { id: personId },
    });

    if (!person || person.ownerId !== userId) {
      continue;
    }

    // Check if assignment already exists
    const existing = await prisma.questionAssignment.findFirst({
      where: { questionId, personId },
    });

    if (existing) {
      assignments.push({
        id: existing.id,
        question_id: existing.questionId,
        person_id: existing.personId,
        status: existing.status,
        unique_link_token: existing.uniqueLinkToken,
        recording_link: `${appUrl}/record/${existing.uniqueLinkToken}`,
      });
      continue;
    }

    const token = generateLinkToken();
    const assignment = await prisma.questionAssignment.create({
      data: {
        questionId,
        personId,
        uniqueLinkToken: token,
      },
    });

    assignments.push({
      id: assignment.id,
      question_id: assignment.questionId,
      person_id: assignment.personId,
      status: assignment.status,
      unique_link_token: assignment.uniqueLinkToken,
      recording_link: `${appUrl}/record/${token}`,
    });
  }

  return { assignments };
}
