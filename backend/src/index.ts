import 'dotenv/config';
import app from './app.js';
import { syncSelfPersonsWithUsers } from './services/users.service.js';

const PORT = process.env.PORT || 3000;

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API base: http://localhost:${PORT}/v1`);

  // Sync self-persons with their user accounts on startup
  await syncSelfPersonsWithUsers();
});
