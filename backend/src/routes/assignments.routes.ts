import { Router, Request, Response, NextFunction } from 'express';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { sendLimiter } from '../middleware/rateLimit.js';
import { sendAssignmentSchema, assignmentIdSchema } from '../validators/questions.validators.js';
import * as assignmentsService from '../services/assignments.service.js';
import { success, noContent } from '../utils/responses.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /assignments/:assignment_id/send
router.post(
  '/:assignment_id/send',
  sendLimiter,
  validate({ params: assignmentIdSchema, body: sendAssignmentSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await assignmentsService.sendAssignment(
        req.user!.userId,
        req.params.assignment_id as string,
        req.body
      );
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /assignments/:assignment_id/remind
router.post(
  '/:assignment_id/remind',
  sendLimiter,
  validate({ params: assignmentIdSchema, body: sendAssignmentSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await assignmentsService.sendReminder(
        req.user!.userId,
        req.params.assignment_id as string,
        req.body
      );
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /assignments/:assignment_id
router.delete(
  '/:assignment_id',
  validate({ params: assignmentIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await assignmentsService.deleteAssignment(req.user!.userId, req.params.assignment_id as string);
      noContent(res);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
