import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../middleware/auth.js';
import * as statsService from '../services/stats.service.js';
import { success } from '../utils/responses.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /stats/dashboard
router.get('/dashboard', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const stats = await statsService.getDashboardStats(req.user!.userId);
    success(res, stats);
  } catch (err) {
    next(err);
  }
});

export default router;
