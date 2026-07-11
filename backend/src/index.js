import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { agentsRouter } from './routes/agents.js';
import { authMiddleware } from './middleware/auth.js';
import { sessionStore } from './services/sessionStore.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api', authMiddleware);
app.use('/api/agents', agentsRouter);

await sessionStore.initialize();

app.listen(PORT, HOST, () => {
  console.log(`Pocket Dev Team server running at http://${HOST}:${PORT}`);
  console.log('Available agents: Lila (Librarian), Cody (Coder), Quinn (QA)');
});
