import { Router } from 'express';
import { 
  getAgents, 
  getAgentHistory, 
  clearAgentSession, 
  streamAgentResponse 
} from '../services/agentService.js';

export const agentsRouter = Router();

agentsRouter.get('/', (req, res) => {
  const agents = getAgents();
  res.json({ agents });
});

agentsRouter.get('/:id/history', (req, res) => {
  const { id } = req.params;
  const history = getAgentHistory(id);
  res.json({ 
    agentId: id,
    messages: history 
  });
});

agentsRouter.post('/:id/message', async (req, res) => {
  const { id } = req.params;
  const { message } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');

  try {
    for await (const event of streamAgentResponse(id, message)) {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
      
      if (event.type === 'done' || event.type === 'error') {
        break;
      }
    }
  } catch (error) {
    res.write(`data: ${JSON.stringify({ type: 'error', error: error.message })}\n\n`);
  }

  res.end();
});

agentsRouter.post('/:id/clear', async (req, res) => {
  const { id } = req.params;
  await clearAgentSession(id);
  res.json({ success: true, message: `Session cleared for ${id}` });
});
