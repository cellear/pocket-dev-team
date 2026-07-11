// Session manager: one persistent Claude Agent SDK session per agent
//
// Each agent's conversation is a Claude Agent SDK `query()` session, scoped to
// the shared project root (cwd), driven by the agent's persona (systemPrompt)
// and model. The SDK persists the real conversation transcript to disk and lets
// us resume it by sessionId.

import { query } from '@anthropic-ai/claude-agent-sdk';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const STATE_PATH = path.join(ROOT, '.sessions.json');
const PERSONAS_DIR = path.join(ROOT, 'personas');

let config;
let state; // { [agentId]: { sessionId, status, history: [{role, text, toolUses, timestamp}] } }

export async function init(cfg) {
  config = cfg;
  
  // Load existing state or initialize
  state = existsSync(STATE_PATH)
    ? JSON.parse(await readFile(STATE_PATH, 'utf8'))
    : {};
  
  // Ensure each agent has state
  for (const agent of config.agents) {
    if (!state[agent.id]) {
      state[agent.id] = { 
        sessionId: null, 
        status: 'idle',
        history: [] 
      };
    }
  }
  
  // Ensure project root exists
  await mkdir(projectRoot(), { recursive: true });
  await persist();
}

function projectRoot() {
  return path.resolve(ROOT, config.projectRoot);
}

function getAgent(id) {
  const agent = config.agents.find((a) => a.id === id);
  if (!agent) throw new Error(`Unknown agent: ${id}`);
  return agent;
}

async function loadPersona(id) {
  const personaPath = path.join(PERSONAS_DIR, `${id}.md`);
  if (existsSync(personaPath)) {
    return readFile(personaPath, 'utf8');
  }
  // Default persona if file doesn't exist
  const agent = getAgent(id);
  return `You are ${agent.name}, the ${agent.role} of a development team. ${agent.description || ''}`;
}

async function persist() {
  await writeFile(STATE_PATH, JSON.stringify(state, null, 2));
}

export function listAgents() {
  return config.agents.map((a) => ({
    id: a.id,
    name: a.name,
    role: a.role,
    description: a.description,
    model: a.model,
    accent: a.accent,
    status: state[a.id]?.status || 'idle',
  }));
}

export function getHistory(id) {
  getAgent(id); // Validate agent exists
  return state[id]?.history ?? [];
}

export function getStatus(id) {
  const agent = getAgent(id);
  const s = state[id];
  return {
    id: agent.id,
    name: agent.name,
    status: s?.status || 'idle',
    lastActivity: s?.history?.slice(-1)[0]?.timestamp || null,
    messageCount: s?.history?.length || 0,
  };
}

export async function clearSession(id) {
  getAgent(id); // Validate agent exists
  state[id] = {
    sessionId: null,
    status: 'idle',
    history: [],
  };
  await persist();
}

// Async generator of UI events
export async function* sendMessage(id, text) {
  const agent = getAgent(id);
  const persona = await loadPersona(id);
  const s = state[id];

  // Record user message
  const userMessage = {
    role: 'user',
    text,
    timestamp: new Date().toISOString(),
  };
  s.history.push(userMessage);
  s.status = 'working';
  await persist();

  yield { type: 'status', status: 'working' };

  const options = {
    cwd: projectRoot(),
    model: agent.model,
    systemPrompt: persona,
    permissionMode: config.permissionMode || 'acceptEdits',
    ...(s.sessionId ? { resume: s.sessionId } : {}),
  };

  let assistantText = '';
  let toolUses = [];

  try {
    for await (const message of query({ prompt: text, options })) {
      // Capture session ID for resume
      if (message.session_id) {
        s.sessionId = message.session_id;
      }

      if (message.type === 'assistant') {
        for (const block of message.message.content) {
          if (block.type === 'text' && block.text) {
            assistantText += block.text;
            yield { type: 'text', text: block.text };
          } else if (block.type === 'tool_use') {
            const toolUse = {
              tool: block.name,
              args: summarizeToolArgs(block.name, block.input),
            };
            toolUses.push(toolUse);
            yield { type: 'tool_start', ...toolUse };
          }
        }
      } else if (message.type === 'tool_result') {
        yield { type: 'tool_end', tool: message.tool_name };
      }
    }
  } catch (err) {
    s.status = 'error';
    await persist();
    yield { type: 'error', message: String(err?.message || err) };
    return;
  }

  // Record assistant response
  if (assistantText) {
    s.history.push({
      role: 'assistant',
      text: assistantText,
      toolUses: toolUses.length > 0 ? toolUses : undefined,
      timestamp: new Date().toISOString(),
    });
  }

  s.status = 'idle';
  await persist();
  
  yield { type: 'status', status: 'idle' };
}

// Summarize tool arguments for UI display (avoid showing full file contents)
function summarizeToolArgs(toolName, args) {
  if (!args) return {};
  
  const summary = { ...args };
  
  // Truncate long content fields
  for (const key of ['content', 'contents', 'text', 'code']) {
    if (typeof summary[key] === 'string' && summary[key].length > 100) {
      summary[key] = summary[key].slice(0, 100) + '...';
    }
  }
  
  return summary;
}
