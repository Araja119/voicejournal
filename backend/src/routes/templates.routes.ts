import { Router, Request, Response, NextFunction } from 'express';
import * as templatesService from '../services/templates.service.js';
import { success } from '../utils/responses.js';

const router = Router();

// GET /templates - No auth required
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const relationship = req.query.relationship as string | undefined;
    const category = req.query.category as string | undefined;

    const templates = await templatesService.listTemplates(relationship, category);
    success(res, { templates });
  } catch (err) {
    next(err);
  }
});

// GET /templates/relationships - No auth required
router.get('/relationships', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const relationships = await templatesService.listRelationships();
    success(res, { relationships });
  } catch (err) {
    next(err);
  }
});

export default router;
