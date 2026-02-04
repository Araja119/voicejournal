import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { fileURLToPath } from 'url';
import { errorHandler } from './middleware/errorHandler.js';
import { generalLimiter } from './middleware/rateLimit.js';
import routes from './routes/index.js';
import webRoutes from './routes/web.routes.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      mediaSrc: ["'self'", "blob:"],
      connectSrc: ["'self'"],
    },
  },
}));
app.use(cors());

// Rate limiting
app.use(generalLimiter);

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static uploads (local development only; production uses R2)
if (process.env.NODE_ENV !== 'production') {
  app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
}

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Web recording page (served as HTML at root level)
app.use('/record', webRoutes);

// API routes
app.use('/v1', routes);

// Error handling (must be last)
app.use(errorHandler);

export default app;
