import prisma from '../utils/prisma.js';
import { NotFoundError, ForbiddenError } from '../utils/errors.js';
import type { NotificationsQueryInput } from '../validators/notifications.validators.js';

export interface NotificationSummary {
  id: string;
  type: string;
  title: string | null;
  body: string | null;
  related_recording_id: string | null;
  related_journal_id: string | null;
  read: boolean;
  sent_at: Date;
}

export async function listNotifications(
  userId: string,
  query: NotificationsQueryInput
): Promise<{ notifications: NotificationSummary[]; unread_count: number }> {
  const limit = query.limit || 50;

  const whereConditions: any = {
    recipientUserId: userId,
  };

  if (query.unread_only) {
    whereConditions.readAt = null;
  }

  const [notifications, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: whereConditions,
      include: {
        relatedAssignment: {
          include: {
            question: {
              include: { journal: true },
            },
          },
        },
      },
      orderBy: { sentAt: 'desc' },
      take: limit,
    }),
    prisma.notification.count({
      where: {
        recipientUserId: userId,
        readAt: null,
      },
    }),
  ]);

  return {
    notifications: notifications.map((n) => ({
      id: n.id,
      type: n.notificationType,
      title: n.title,
      body: n.body,
      related_recording_id: n.relatedRecordingId,
      related_journal_id: n.relatedAssignment?.question.journalId || null,
      read: n.readAt !== null,
      sent_at: n.sentAt,
    })),
    unread_count: unreadCount,
  };
}

export async function markAsRead(userId: string, notificationId: string): Promise<void> {
  const notification = await prisma.notification.findUnique({
    where: { id: notificationId },
  });

  if (!notification) {
    throw new NotFoundError('Notification');
  }

  if (notification.recipientUserId !== userId) {
    throw new ForbiddenError('You do not have access to this notification');
  }

  await prisma.notification.update({
    where: { id: notificationId },
    data: { readAt: new Date() },
  });
}

export async function markAllAsRead(userId: string): Promise<void> {
  await prisma.notification.updateMany({
    where: {
      recipientUserId: userId,
      readAt: null,
    },
    data: { readAt: new Date() },
  });
}
