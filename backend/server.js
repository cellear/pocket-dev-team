// Pocket Dev Team — backend server for mobile AI agent interface
// Exposes REST API + SSE streaming for iOS app consumption

import express from 'express';
import cors from 'cors';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFile } from 'node:fs/promises';
import * as sessions from './lib/sessions.js';
import * as auth from './lib/auth.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const config = JSON.parse(
  await readFile(path.join(__dirname, 'config.json'), 'utf8'),
);

await sessions.init(config);

const app = express();

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: '0.1.0' });
});

// Auth middleware for protected routes
const requireAuth = (req, res, next) => {
  if (!config.auth.enabled) return next();
  
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token || !auth.validateToken(token, config)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

// List available agents
app.get('/api/agents', requireAuth, (req, res) => {
  res.json(sessions.listAgents());
});

// Get agent conversation history
app.get('/api/agents/:id/history', requireAuth, (req, res) => {
  try {
    const history = sessions.getHistory(req.params.id);
    res.json(history);
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
});

// Get agent status (working, idle, needs input)
app.get('/api/agents/:id/status', requireAuth, (req, res) => {
  try {
    const status = sessions.getStatus(req.params.id);
    res.json(status);
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
});

// Send message to agent — returns SSE stream
app.post('/api/agents/:id/message', requireAuth, async (req, res) => {
  const text = (req.body?.text ?? '').toString().trim();
  
  if (!text) {
    return res.status(400).json({ error: 'Message text required' });
  }

  // Set up SSE
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders?.();

  try {
    for await (const event of sessions.sendMessage(req.params.id, text)) {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    }
  } catch (err) {
    res.write(
      `data: ${JSON.stringify({ type: 'error', message: String(err?.message || err) })}\n\n`,
    );
  }

  res.write(`data: ${JSON.stringify({ type: 'done' })}\n\n`);
  res.end();
});

// Clear agent conversation (start fresh)
app.post('/api/agents/:id/clear', requireAuth, async (req, res) => {
  try {
    await sessions.clearSession(req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
});

// Get workspace info
app.get('/api/workspace', requireAuth, (req, res) => {
  res.json({
    projectRoot: path.resolve(__dirname, config.projectRoot),
    permissionMode: config.permissionMode,
  });
});

// Register device for push notifications
app.post('/api/push/register', requireAuth, (req, res) => {
  const { deviceToken, platform } = req.body;
  
  if (!deviceToken) {
    return res.status(400).json({ error: 'deviceToken required' });
  }
  
  // TODO: Store device token for push notifications
  console.log(`Registered device: ${platform} ${deviceToken.slice(0, 16)}...`);
  res.json({ success: true });
});

// Start server
const port = config.port || 3000;
app.listen(port, () => {
  console.log(`\n🚀 Pocket Dev Team server running at http://localhost:${port}`);
  console.log(`📁 Project root: ${path.resolve(__dirname, config.projectRoot)}`);
  console.log(`🔐 Auth: ${config.auth.enabled ? 'enabled' : 'disabled'}`);
  console.log(`\nAgents available:`);
  for (const agent of config.agents) {
    console.log(`   • ${agent.name} (${agent.role}) — ${agent.model}`);
  }
  console.log('');
});
