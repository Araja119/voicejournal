import { Router, Request, Response, NextFunction } from 'express';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import {
  createQuestionSchema,
  bulkCreateQuestionsSchema,
  updateQuestionSchema,
  reorderQuestionsSchema,
  journalIdSchema,
  questionIdSchema,
  assignQuestionSchema,
  questionIdOnlySchema,
} from '../validators/questions.validators.js';
import * as questionsService from '../services/questions.service.js';
import { success, created } from '../utils/responses.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /questions/:question_id/assign
router.post(
  '/:question_id/assign',
  validate({ params: questionIdOnlySchema, body: assignQuestionSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await questionsService.assignQuestion(
        req.user!.userId,
        req.params.question_id as string,
        req.body
      );
      created(res, result);
    } catch (err) {
      next(err);
    }
  }
);

export default router;

// Journal-scoped question routes are defined separately
export const journalQuestionsRouter = Router({ mergeParams: true });

// POST /journals/:journal_id/questions
journalQuestionsRouter.post(
  '/',
  authenticate,
  validate({ params: journalIdSchema, body: createQuestionSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const question = await questionsService.createQuestion(
        req.user!.userId,
        req.params.journal_id as string,
        req.body
      );
      created(res, question);
    } catch (err) {
      next(err);
    }
  }
);

// POST /journals/:journal_id/questions/bulk
journalQuestionsRouter.post(
  '/bulk',
  authenticate,
  validate({ params: journalIdSchema, body: bulkCreateQuestionsSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await questionsService.bulkCreateQuestions(
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

// PATCH /journals/:journal_id/questions/reorder - must come before /:question_id
journalQuestionsRouter.patch(
  '/reorder',
  authenticate,
  validate({ params: journalIdSchema, body: reorderQuestionsSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await questionsService.reorderQuestions(
        req.user!.userId,
        req.params.journal_id as string,
        req.body
      );
      success(res, { message: 'Questions reordered successfully' });
    } catch (err) {
      next(err);
    }
  }
);

// PATCH /journals/:journal_id/questions/:question_id
journalQuestionsRouter.patch(
  '/:question_id',
  authenticate,
  validate({ params: questionIdSchema, body: updateQuestionSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const question = await questionsService.updateQuestion(
        req.user!.userId,
        req.params.journal_id as string,
        req.params.question_id as string,
        req.body
      );
      success(res, question);
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /journals/:journal_id/questions/:question_id
journalQuestionsRouter.delete(
  '/:question_id',
  authenticate,
  validate({ params: questionIdSchema }),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await questionsService.deleteQuestion(
        req.user!.userId,
        req.params.journal_id as string,
        req.params.question_id as string
      );
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
);
