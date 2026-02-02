import { z } from 'zod';

export const relationshipTypes = [
  'self',
  'parent',
  'grandparent',
  'spouse',
  'partner',
  'sibling',
  'child',
  'friend',
  'coworker',
  'boss',
  'mentor',
  'other',
] as const;

export const createPersonSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  relationship: z.enum(relationshipTypes),
  email: z.string().email().optional().or(z.literal('')),
  phone_number: z.string().optional(),
  linked_user_id: z.string().uuid().optional(),
});

export const updatePersonSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  relationship: z.enum(relationshipTypes).optional(),
  email: z.string().email().optional().or(z.literal('')),
  phone_number: z.string().optional(),
});

export const personIdSchema = z.object({
  id: z.string().uuid(),
});

export type CreatePersonInput = z.infer<typeof createPersonSchema>;
export type UpdatePersonInput = z.infer<typeof updatePersonSchema>;
