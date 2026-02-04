import { Router, Request, Response, NextFunction } from 'express';
import * as recordingsService from '../services/recordings.service.js';
import { renderRecordingPage } from '../views/record-page.js';

const router = Router();

// GET /record/:link_token — Serve recording page HTML
router.get('/:link_token', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await recordingsService.getRecordingPageData(req.params.link_token as string);
    const html = renderRecordingPage(data, req.params.link_token as string);
    res.type('html').send(html);
  } catch (err: any) {
    // Show a simple error page instead of JSON for web visitors
    if (err.statusCode === 404) {
      res.status(404).type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VoiceJournal — Link Not Found</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: #fff; min-height: 100vh;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      padding: 24px; text-align: center;
    }
    h1 { font-size: 24px; margin-bottom: 12px; }
    p { color: rgba(255,255,255,0.6); font-size: 16px; }
  </style>
</head>
<body>
  <h1>Link Not Found</h1>
  <p>This recording link is invalid or has expired.</p>
</body>
</html>`);
    } else {
      next(err);
    }
  }
});

export default router;
