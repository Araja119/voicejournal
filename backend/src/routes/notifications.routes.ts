import { Router, Request, Response, NextFunction } from 'express';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import {
  notificationsQuerySchema,
  notificationIdSchema,
} from '../validators/notifications.validators.js';
import * as notificationsService from '../services/notifications.service.js';
import { success } from '../utils/responses.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /notifications
router.get(
  '/',
  validate({ query: notificationsQuerySchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await notificationsService.listNotifications(req.user!.userId, req.query as any);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// PATCH /notifications/:notification_id/read
router.patch(
  '/:notification_id/read',
  validate({ params: notificationIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await notificationsService.markAsRead(req.user!.userId, req.params.notification_id as string);
      success(res, { message: 'Marked as read' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /notifications/read-all
router.post('/read-all', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await notificationsService.markAllAsRead(req.user!.userId);
    success(res, { message: 'All notifications marked as read' });
  } catch (err) {
    next(err);
  }
});

export default router;
