import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { validate } from '../middleware/validate.js';
import { authenticate, optionalAuth } from '../middleware/auth.js';
import { uploadLimiter } from '../middleware/rateLimit.js';
import {
  createJournalSchema,
  updateJournalSchema,
  journalIdSchema,
  shareCodeSchema,
  collaboratorIdSchema,
  addCollaboratorSchema,
  journalQuerySchema,
} from '../validators/journals.validators.js';
import * as journalsService from '../services/journals.service.js';
import * as aiService from '../services/ai.service.js';
import * as recordingsService from '../services/recordings.service.js';
import { success, created, noContent } from '../utils/responses.js';
import { ValidationError } from '../utils/errors.js';

const router = Router();

// Multer config for image uploads
const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new ValidationError('Only image files are allowed'));
    }
  },
});

// Multer config for audio uploads
const audioUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new ValidationError('Only audio files are allowed'));
    }
  },
});

// Legacy alias
const upload = imageUpload;

// GET /journals/shared/:share_code - Can be accessed without auth for public journals
router.get(
  '/shared/:share_code',
  optionalAuth,
  validate({ params: shareCodeSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journal = await journalsService.getJournalByShareCode(
        req.params.share_code as string,
        req.user?.userId
      );
      success(res, journal);
    } catch (err) {
      next(err);
    }
  }
);

// All other routes require authentication
router.use(authenticate);

// GET /journals
router.get(
  '/',
  validate({ query: journalQuerySchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journals = await journalsService.listJournals(req.user!.userId, req.query as any);
      success(res, { journals });
    } catch (err) {
      next(err);
    }
  }
);

// POST /journals
router.post(
  '/',
  validate({ body: createJournalSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journal = await journalsService.createJournal(req.user!.userId, req.body);
      created(res, journal);
    } catch (err) {
      next(err);
    }
  }
);

// GET /journals/:journal_id
router.get(
  '/:journal_id',
  validate({ params: journalIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journal = await journalsService.getJournal(req.user!.userId, req.params.journal_id as string);
      success(res, journal);
    } catch (err) {
      next(err);
    }
  }
);

// GET /journals/:journal_id/suggested-questions
router.get(
  '/:journal_id/suggested-questions',
  validate({ params: journalIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journal = await journalsService.getJournal(req.user!.userId, req.params.journal_id as string);

      // Extract existing question texts to avoid duplicates
      const existingQuestions = journal.questions.map(q => q.question_text);

      // Generate AI suggestions
      const count = parseInt(req.query.count as string) || 3;
      const suggestions = await aiService.generateSuggestedQuestions({
        journalTitle: journal.title,
        journalDescription: journal.description,
        recipientName: journal.dedicated_to_person?.name,
        recipientRelationship: journal.dedicated_to_person?.relationship,
        existingQuestions,
      }, count);

      success(res, { suggestions });
    } catch (err) {
      next(err);
    }
  }
);

// PATCH /journals/:journal_id
router.patch(
  '/:journal_id',
  validate({ params: journalIdSchema, body: updateJournalSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const journal = await journalsService.updateJournal(
        req.user!.userId,
        req.params.journal_id as string,
        req.body
      );
      success(res, journal);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /journals/:journal_id
router.delete(
  '/:journal_id',
  validate({ params: journalIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await journalsService.deleteJournal(req.user!.userId, req.params.journal_id as string);
      noContent(res);
    } catch (err) {
      next(err);
    }
  }
);

// POST /journals/:journal_id/cover-image
router.post(
  '/:journal_id/cover-image',
  validate({ params: journalIdSchema }),
  uploadLimiter,
  upload.single('image'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) {
        throw new ValidationError('No file uploaded');
      }

      const result = await journalsService.updateCoverImage(
        req.user!.userId,
        req.params.journal_id as string,
        req.file.buffer,
        req.file.mimetype
      );

      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// GET /journals/:journal_id/collaborators
router.get(
  '/:journal_id/collaborators',
  validate({ params: journalIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await journalsService.listCollaborators(
        req.user!.userId,
        req.params.journal_id as string
      );
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /journals/:journal_id/collaborators
router.post(
  '/:journal_id/collaborators',
  validate({ params: journalIdSchema, body: addCollaboratorSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await journalsService.addCollaborator(
        req.user!.userId,
        req.params.journal_id as string,
        req.body
      );
      created(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /journals/:journal_id/collaborators/:collaborator_id
router.delete(
  '/:journal_id/collaborators/:collaborator_id',
  validate({ params: collaboratorIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await journalsService.removeCollaborator(
        req.user!.userId,
        req.params.journal_id as string,
        req.params.collaborator_id as string
      );
      noContent(res);
    } catch (err) {
      next(err);
    }
  }
);

// POST /journals/:journal_id/questions/:question_id/recordings
// Authenticated recording upload for self-recording flow
router.post(
  '/:journal_id/questions/:question_id/recordings',
  uploadLimiter,
  audioUpload.single('audio'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) {
        throw new ValidationError('No audio file uploaded');
      }

      const { journal_id, question_id } = req.params;
      const userId = req.user!.userId;
      const idempotencyKey = req.headers['idempotency-key'] as string | undefined;
      const durationSeconds = req.body.duration_seconds
        ? parseInt(req.body.duration_seconds, 10)
        : undefined;

      const recording = await recordingsService.createAuthenticatedRecording(
        userId,
        journal_id as string,
        question_id as string,
        req.file.buffer,
        req.file.mimetype,
        durationSeconds,
        idempotencyKey
      );

      created(res, recording);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
