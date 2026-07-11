import { promises as fs } from 'fs';
import path from 'path';

const DATA_PATH = process.env.SESSION_DATA_PATH || './data/sessions';

class SessionStore {
  constructor() {
    this.sessions = new Map();
    this.dataPath = DATA_PATH;
  }

  async initialize() {
    try {
      await fs.mkdir(this.dataPath, { recursive: true });
      await this.loadSessions();
      console.log('Session store initialized');
    } catch (error) {
      console.error('Failed to initialize session store:', error);
    }
  }

  async loadSessions() {
    try {
      const files = await fs.readdir(this.dataPath);
      for (const file of files) {
        if (file.endsWith('.json')) {
          const sessionId = file.replace('.json', '');
          const data = await fs.readFile(path.join(this.dataPath, file), 'utf-8');
          this.sessions.set(sessionId, JSON.parse(data));
        }
      }
      console.log(`Loaded ${this.sessions.size} sessions`);
    } catch (error) {
      if (error.code !== 'ENOENT') {
        console.error('Failed to load sessions:', error);
      }
    }
  }

  async saveSession(sessionId, data) {
    this.sessions.set(sessionId, data);
    try {
      await fs.writeFile(
        path.join(this.dataPath, `${sessionId}.json`),
        JSON.stringify(data, null, 2)
      );
    } catch (error) {
      console.error('Failed to save session:', error);
    }
  }

  getSession(sessionId) {
    return this.sessions.get(sessionId) || null;
  }

  async deleteSession(sessionId) {
    this.sessions.delete(sessionId);
    try {
      await fs.unlink(path.join(this.dataPath, `${sessionId}.json`));
    } catch (error) {
      if (error.code !== 'ENOENT') {
        console.error('Failed to delete session:', error);
      }
    }
  }

  getConversationHistory(agentId) {
    const session = this.sessions.get(agentId);
    return session?.messages || [];
  }

  async addMessage(agentId, role, content) {
    let session = this.sessions.get(agentId) || { messages: [], createdAt: new Date().toISOString() };
    session.messages.push({
      role,
      content,
      timestamp: new Date().toISOString()
    });
    session.updatedAt = new Date().toISOString();
    await this.saveSession(agentId, session);
  }

  async clearSession(agentId) {
    await this.deleteSession(agentId);
  }
}

export const sessionStore = new SessionStore();
