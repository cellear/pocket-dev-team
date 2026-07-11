import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PERSONAS_PATH = path.join(__dirname, '../../personas');

const agentMetadata = {
  lila: {
    id: 'lila',
    name: 'Lila',
    role: 'Librarian',
    emoji: '📚',
    description: 'Codebase explorer and documentation expert',
    color: '#8B5CF6'
  },
  cody: {
    id: 'cody',
    name: 'Cody',
    role: 'Coder',
    emoji: '💻',
    description: 'Implementation specialist and code writer',
    color: '#10B981'
  },
  quinn: {
    id: 'quinn',
    name: 'Quinn',
    role: 'QA',
    emoji: '🔍',
    description: 'Quality assurance and testing expert',
    color: '#F59E0B'
  }
};

class PersonaLoader {
  constructor() {
    this.personas = new Map();
  }

  async loadAll() {
    for (const agentId of Object.keys(agentMetadata)) {
      try {
        const personaPath = path.join(PERSONAS_PATH, `${agentId}.md`);
        const content = await fs.readFile(personaPath, 'utf-8');
        this.personas.set(agentId, {
          ...agentMetadata[agentId],
          systemPrompt: content
        });
      } catch (error) {
        console.error(`Failed to load persona for ${agentId}:`, error.message);
        this.personas.set(agentId, {
          ...agentMetadata[agentId],
          systemPrompt: this.getDefaultPrompt(agentId)
        });
      }
    }
    console.log(`Loaded ${this.personas.size} personas`);
  }

  getDefaultPrompt(agentId) {
    const meta = agentMetadata[agentId];
    return `You are ${meta.name}, the ${meta.role} in the Pocket Dev Team. ${meta.description}.`;
  }

  getPersona(agentId) {
    return this.personas.get(agentId) || null;
  }

  getAllAgents() {
    return Array.from(this.personas.values()).map(p => ({
      id: p.id,
      name: p.name,
      role: p.role,
      emoji: p.emoji,
      description: p.description,
      color: p.color
    }));
  }
}

export const personaLoader = new PersonaLoader();
await personaLoader.loadAll();
