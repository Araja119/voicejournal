import { z } from 'zod';

export const updateUserSchema = z.object({
  display_name: z.string().min(1).max(100).optional(),
  phone_number: z.string().optional(),
});

export const pushTokenSchema = z.object({
  token: z.string().min(1, 'Token is required'),
  platform: z.enum(['ios', 'android', 'web']),
});

export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type PushTokenInput = z.infer<typeof pushTokenSchema>;
