import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { uploadLimiter } from '../middleware/rateLimit.js';
import { updateUserSchema, pushTokenSchema } from '../validators/users.validators.js';
import * as usersService from '../services/users.service.js';
import { success } from '../utils/responses.js';
import { ValidationError } from '../utils/errors.js';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new ValidationError('Only image files are allowed'));
    }
  },
});

// All user routes require authentication
router.use(authenticate);

// GET /users/me
router.get('/me', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profile = await usersService.getProfile(req.user!.userId);
    success(res, profile);
  } catch (err) {
    next(err);
  }
});

// PATCH /users/me
router.patch(
  '/me',
  validate({ body: updateUserSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const profile = await usersService.updateProfile(req.user!.userId, req.body);
      success(res, profile);
    } catch (err) {
      next(err);
    }
  }
);

// POST /users/me/profile-photo
router.post(
  '/me/profile-photo',
  uploadLimiter,
  upload.single('photo'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) {
        throw new ValidationError('No file uploaded');
      }

      const result = await usersService.updateProfilePhoto(
        req.user!.userId,
        req.file.buffer,
        req.file.mimetype
      );

      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /users/me/push-token
router.post(
  '/me/push-token',
  validate({ body: pushTokenSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await usersService.registerPushToken(req.user!.userId, req.body);
      success(res, { message: 'Push token registered' });
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /users/me - Delete account
router.delete('/me', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await usersService.deleteAccount(req.user!.userId);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
