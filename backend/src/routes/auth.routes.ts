import { Router, Request, Response, NextFunction } from 'express';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimit.js';
import {
  signupSchema,
  loginSchema,
  refreshSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../validators/auth.validators.js';
import * as authService from '../services/auth.service.js';
import { success, created } from '../utils/responses.js';

const router = Router();

// Apply rate limiting to all auth routes
router.use(authLimiter);

// POST /auth/signup
router.post(
  '/signup',
  validate({ body: signupSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.signup(req.body);
      created(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/login
router.post(
  '/login',
  validate({ body: loginSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.login(req.body);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/refresh
router.post(
  '/refresh',
  validate({ body: refreshSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.refreshTokens(req.body.refresh_token);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/logout
router.post(
  '/logout',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await authService.logout(req.user!.userId);
      success(res, { message: 'Logged out successfully' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/forgot-password
router.post(
  '/forgot-password',
  validate({ body: forgotPasswordSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await authService.forgotPassword(req.body.email);
      success(res, { message: 'If an account exists, a reset link has been sent' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/reset-password
router.post(
  '/reset-password',
  validate({ body: resetPasswordSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await authService.resetPassword(req.body.token, req.body.new_password);
      success(res, { message: 'Password reset successfully' });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
