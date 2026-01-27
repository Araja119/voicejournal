import prisma from '../utils/prisma.js';

export interface DashboardStats {
  total_journals: number;
  total_recordings: number;
  total_recording_minutes: number;
  total_people: number;
  pending_questions: number;
  recent_activity: Array<{
    type: string;
    description: string;
    timestamp: Date;
  }>;
}

export async function getDashboardStats(userId: string): Promise<DashboardStats> {
  const [
    journalCount,
    recordings,
    peopleCount,
    pendingAssignments,
    recentNotifications,
  ] = await Promise.all([
    // Total journals owned
    prisma.journal.count({
      where: { ownerId: userId },
    }),

    // All recordings with duration
    prisma.recording.findMany({
      where: {
        assignment: {
          question: {
            journal: { ownerId: userId },
          },
        },
      },
      select: { durationSeconds: true },
    }),

    // Total people
    prisma.person.count({
      where: { ownerId: userId },
    }),

    // Pending questions (assignments not answered)
    prisma.questionAssignment.count({
      where: {
        status: { in: ['pending', 'sent', 'viewed'] },
        question: {
          journal: { ownerId: userId },
        },
      },
    }),

    // Recent activity from notifications
    prisma.notification.findMany({
      where: { recipientUserId: userId },
      orderBy: { sentAt: 'desc' },
      take: 10,
      select: {
        notificationType: true,
        body: true,
        sentAt: true,
      },
    }),
  ]);

  // Calculate total recording minutes
  const totalSeconds = recordings.reduce((sum, r) => sum + (r.durationSeconds || 0), 0);
  const totalMinutes = Math.round(totalSeconds / 60);

  // Format recent activity
  const recentActivity = recentNotifications.map((n) => ({
    type: n.notificationType,
    description: n.body || getActivityDescription(n.notificationType),
    timestamp: n.sentAt,
  }));

  return {
    total_journals: journalCount,
    total_recordings: recordings.length,
    total_recording_minutes: totalMinutes,
    total_people: peopleCount,
    pending_questions: pendingAssignments,
    recent_activity: recentActivity,
  };
}

function getActivityDescription(type: string): string {
  switch (type) {
    case 'recording_received':
      return 'New recording received';
    case 'question_received':
      return 'New question received';
    case 'journal_shared':
      return 'Journal shared with you';
    case 'reminder':
      return 'Reminder sent';
    default:
      return 'Activity';
  }
}
