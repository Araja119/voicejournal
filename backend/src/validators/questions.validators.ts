import { z } from 'zod';

export const createQuestionSchema = z.object({
  question_text: z.string().min(1, 'Question text is required').max(1000),
  template_id: z.string().uuid().optional(),
  assign_to_person_ids: z.array(z.string().uuid()).optional(),
});

export const bulkCreateQuestionsSchema = z.object({
  questions: z.array(
    z.object({
      question_text: z.string().min(1).max(1000),
      template_id: z.string().uuid().optional(),
    })
  ).min(1),
  assign_to_person_ids: z.array(z.string().uuid()).optional(),
});

export const updateQuestionSchema = z.object({
  question_text: z.string().min(1).max(1000).optional(),
  display_order: z.number().int().min(0).optional(),
});

export const reorderQuestionsSchema = z.object({
  question_ids: z.array(z.string().uuid()).min(1),
});

export const journalIdSchema = z.object({
  journal_id: z.string().uuid(),
});

export const questionIdSchema = z.object({
  journal_id: z.string().uuid(),
  question_id: z.string().uuid(),
});

export const assignQuestionSchema = z.object({
  person_ids: z.array(z.string().uuid()).min(1),
});

export const sendAssignmentSchema = z.object({
  channel: z.enum(['sms', 'email', 'share']),
});

export const assignmentIdSchema = z.object({
  assignment_id: z.string().uuid(),
});

export const questionIdOnlySchema = z.object({
  question_id: z.string().uuid(),
});

export type CreateQuestionInput = z.infer<typeof createQuestionSchema>;
export type BulkCreateQuestionsInput = z.infer<typeof bulkCreateQuestionsSchema>;
export type UpdateQuestionInput = z.infer<typeof updateQuestionSchema>;
export type ReorderQuestionsInput = z.infer<typeof reorderQuestionsSchema>;
export type AssignQuestionInput = z.infer<typeof assignQuestionSchema>;
export type SendAssignmentInput = z.infer<typeof sendAssignmentSchema>;
