import { z } from 'zod';

export const linkTokenSchema = z.object({
  link_token: z.string().min(1),
});

export const recordingIdSchema = z.object({
  recording_id: z.string().uuid(),
});

export const recordingsQuerySchema = z.object({
  journal_id: z.string().uuid().optional(),
  person_id: z.string().uuid().optional(),
  limit: z.string().transform(Number).pipe(z.number().int().min(1).max(100)).optional(),
  offset: z.string().transform(Number).pipe(z.number().int().min(0)).optional(),
});

export type RecordingsQueryInput = z.infer<typeof recordingsQuerySchema>;
