import { Router } from 'express';
import authRoutes from './auth.routes.js';
import usersRoutes from './users.routes.js';
import peopleRoutes from './people.routes.js';
import templatesRoutes from './templates.routes.js';
import journalsRoutes from './journals.routes.js';
import questionsRoutes, { journalQuestionsRouter } from './questions.routes.js';
import assignmentsRoutes from './assignments.routes.js';
import recordingsRoutes, { recordPublicRouter } from './recordings.routes.js';
import notificationsRoutes from './notifications.routes.js';
import statsRoutes from './stats.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/people', peopleRoutes);
router.use('/templates', templatesRoutes);
router.use('/journals', journalsRoutes);
router.use('/journals/:journal_id/questions', journalQuestionsRouter);
router.use('/questions', questionsRoutes);
router.use('/assignments', assignmentsRoutes);
router.use('/recordings', recordingsRoutes);
router.use('/record', recordPublicRouter); // Public recording routes
router.use('/notifications', notificationsRoutes);
router.use('/stats', statsRoutes);

export default router;
