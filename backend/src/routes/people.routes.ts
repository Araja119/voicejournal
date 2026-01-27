import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { uploadLimiter } from '../middleware/rateLimit.js';
import {
  createPersonSchema,
  updatePersonSchema,
  personIdSchema,
} from '../validators/people.validators.js';
import * as peopleService from '../services/people.service.js';
import { success, created, noContent } from '../utils/responses.js';
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

// All routes require authentication
router.use(authenticate);

// GET /people
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const people = await peopleService.listPeople(req.user!.userId);
    success(res, { people });
  } catch (err) {
    next(err);
  }
});

// POST /people
router.post(
  '/',
  validate({ body: createPersonSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const person = await peopleService.createPerson(req.user!.userId, req.body);
      created(res, person);
    } catch (err) {
      next(err);
    }
  }
);

// GET /people/:id
router.get(
  '/:id',
  validate({ params: personIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const person = await peopleService.getPerson(req.user!.userId, req.params.id as string);
      success(res, person);
    } catch (err) {
      next(err);
    }
  }
);

// PATCH /people/:id
router.patch(
  '/:id',
  validate({ params: personIdSchema, body: updatePersonSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const person = await peopleService.updatePerson(req.user!.userId, req.params.id as string, req.body);
      success(res, person);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /people/:id
router.delete(
  '/:id',
  validate({ params: personIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await peopleService.deletePerson(req.user!.userId, req.params.id as string);
      noContent(res);
    } catch (err) {
      next(err);
    }
  }
);

// POST /people/:id/photo
router.post(
  '/:id/photo',
  validate({ params: personIdSchema }),
  uploadLimiter,
  upload.single('photo'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) {
        throw new ValidationError('No file uploaded');
      }

      const result = await peopleService.updatePersonPhoto(
        req.user!.userId,
        req.params.id as string,
        req.file.buffer,
        req.file.mimetype
      );

      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
