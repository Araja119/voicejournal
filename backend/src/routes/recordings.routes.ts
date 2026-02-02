import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { uploadLimiter } from '../middleware/rateLimit.js';
import {
  linkTokenSchema,
  recordingIdSchema,
  recordingsQuerySchema,
} from '../validators/recordings.validators.js';
import * as recordingsService from '../services/recordings.service.js';
import { success, created, noContent, accepted } from '../utils/responses.js';
import { ValidationError } from '../utils/errors.js';

const router = Router();
const publicRouter = Router(); // Separate router for public routes

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB for audio
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new ValidationError('Only audio files are allowed'));
    }
  },
});

// ==========================================
// AUTHENTICATED ROUTES (on main router, mounted at /recordings)
// ==========================================

// GET /recordings - List all recordings
router.get(
  '/',
  authenticate,
  validate({ query: recordingsQuerySchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await recordingsService.listRecordings(req.user!.userId, req.query as any);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// GET /recordings/:recording_id - Get specific recording
router.get(
  '/:recording_id',
  authenticate,
  validate({ params: recordingIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const recording = await recordingsService.getRecording(
        req.user!.userId,
        req.params.recording_id as string
      );
      success(res, recording);
    } catch (err) {
      next(err);
    }
  }
);

// ==========================================
// PUBLIC ROUTES (on publicRouter, mounted at /record)
// ==========================================

// GET /record/:link_token - Get recording page data
publicRouter.get(
  '/:link_token',
  validate({ params: linkTokenSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await recordingsService.getRecordingPageData(req.params.link_token as string);
      success(res, data);
    } catch (err) {
      next(err);
    }
  }
);

// POST /record/:link_token/upload - Upload recording
publicRouter.post(
  '/:link_token/upload',
  uploadLimiter,
  validate({ params: linkTokenSchema }),
  upload.single('audio'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) {
        throw new ValidationError('No audio file uploaded');
      }

      const durationSeconds = req.body.duration_seconds
        ? parseInt(req.body.duration_seconds, 10)
        : undefined;

      const result = await recordingsService.uploadRecording(
        req.params.link_token as string,
        req.file.buffer,
        durationSeconds
      );

      created(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /recordings/:recording_id - Delete recording
router.delete(
  '/:recording_id',
  authenticate,
  validate({ params: recordingIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await recordingsService.deleteRecording(req.user!.userId, req.params.recording_id as string);
      noContent(res);
    } catch (err) {
      next(err);
    }
  }
);

// POST /recordings/:recording_id/transcribe - Request transcription
router.post(
  '/:recording_id/transcribe',
  authenticate,
  validate({ params: recordingIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await recordingsService.requestTranscription(
        req.user!.userId,
        req.params.recording_id as string
      );
      accepted(res, result);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
export { publicRouter as recordPublicRouter };
