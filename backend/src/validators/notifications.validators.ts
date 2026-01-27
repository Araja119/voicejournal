import { z } from 'zod';

export const notificationsQuerySchema = z.object({
  unread_only: z.string().transform(v => v === 'true').optional(),
  limit: z.string().transform(Number).pipe(z.number().int().min(1).max(100)).optional(),
});

export const notificationIdSchema = z.object({
  notification_id: z.string().uuid(),
});

export type NotificationsQueryInput = z.infer<typeof notificationsQuerySchema>;
