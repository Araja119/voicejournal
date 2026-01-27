import { z } from 'zod';

export const createJournalSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200),
  description: z.string().max(1000).optional(),
  privacy_setting: z.enum(['private', 'public', 'shared']).default('private'),
});

export const updateJournalSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).optional(),
  privacy_setting: z.enum(['private', 'public', 'shared']).optional(),
});

export const journalIdSchema = z.object({
  journal_id: z.string().uuid(),
});

export const shareCodeSchema = z.object({
  share_code: z.string().min(1),
});

export const collaboratorIdSchema = z.object({
  journal_id: z.string().uuid(),
  collaborator_id: z.string().uuid(),
});

export const addCollaboratorSchema = z.object({
  email: z.string().email().optional(),
  phone_number: z.string().optional(),
  permission_level: z.enum(['view', 'edit']).default('view'),
}).refine((data) => data.email || data.phone_number, {
  message: 'Either email or phone_number is required',
});

export const journalQuerySchema = z.object({
  owned: z.string().transform(v => v === 'true').optional(),
  shared: z.string().transform(v => v === 'true').optional(),
});

export type CreateJournalInput = z.infer<typeof createJournalSchema>;
export type UpdateJournalInput = z.infer<typeof updateJournalSchema>;
export type AddCollaboratorInput = z.infer<typeof addCollaboratorSchema>;
export type JournalQueryInput = z.infer<typeof journalQuerySchema>;
