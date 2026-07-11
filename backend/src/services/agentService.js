import Anthropic from '@anthropic-ai/sdk';
import { personaLoader } from './personaLoader.js';
import { sessionStore } from './sessionStore.js';

const client = new Anthropic();

const AVAILABLE_TOOLS = [
  {
    name: 'read_file',
    description: 'Read the contents of a file at the given path',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'The file path to read' }
      },
      required: ['path']
    }
  },
  {
    name: 'write_file',
    description: 'Write content to a file at the given path',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'The file path to write' },
        content: { type: 'string', description: 'The content to write' }
      },
      required: ['path', 'content']
    }
  },
  {
    name: 'list_directory',
    description: 'List files and directories at the given path',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'The directory path to list' }
      },
      required: ['path']
    }
  },
  {
    name: 'run_command',
    description: 'Run a shell command',
    input_schema: {
      type: 'object',
      properties: {
        command: { type: 'string', description: 'The command to run' }
      },
      required: ['command']
    }
  },
  {
    name: 'search_code',
    description: 'Search for text patterns in the codebase',
    input_schema: {
      type: 'object',
      properties: {
        pattern: { type: 'string', description: 'The search pattern' },
        path: { type: 'string', description: 'Optional path to search in' }
      },
      required: ['pattern']
    }
  },
  {
    name: 'run_tests',
    description: 'Run test suite for the project',
    input_schema: {
      type: 'object',
      properties: {
        testPath: { type: 'string', description: 'Optional specific test file or directory' }
      },
      required: []
    }
  }
];

function getToolsForAgent(agentId) {
  switch (agentId) {
    case 'lila':
      return AVAILABLE_TOOLS.filter(t => 
        ['read_file', 'list_directory', 'search_code'].includes(t.name)
      );
    case 'cody':
      return AVAILABLE_TOOLS.filter(t => 
        ['read_file', 'write_file', 'list_directory', 'run_command', 'search_code'].includes(t.name)
      );
    case 'quinn':
      return AVAILABLE_TOOLS;
    default:
      return [];
  }
}

function getToolDisplayName(toolName) {
  const displayNames = {
    read_file: 'Reading file',
    write_file: 'Writing file',
    list_directory: 'Listing directory',
    run_command: 'Running command',
    search_code: 'Searching code',
    run_tests: 'Running tests'
  };
  return displayNames[toolName] || `Using ${toolName}`;
}

async function executeToolCall(toolName, toolInput) {
  switch (toolName) {
    case 'read_file':
      return { success: true, content: `[Simulated] Contents of ${toolInput.path}` };
    case 'write_file':
      return { success: true, message: `[Simulated] Wrote to ${toolInput.path}` };
    case 'list_directory':
      return { success: true, files: ['file1.js', 'file2.js', 'folder/'] };
    case 'run_command':
      return { success: true, output: `[Simulated] Output of: ${toolInput.command}` };
    case 'search_code':
      return { success: true, matches: [`Match found for ${toolInput.pattern}`] };
    case 'run_tests':
      return { success: true, passed: 5, failed: 0, output: '[Simulated] All tests passed' };
    default:
      return { error: `Unknown tool: ${toolName}` };
  }
}

export async function* streamAgentResponse(agentId, userMessage) {
  const persona = personaLoader.getPersona(agentId);
  if (!persona) {
    yield { type: 'error', error: 'Agent not found' };
    return;
  }

  const history = sessionStore.getConversationHistory(agentId);
  
  const messages = [
    ...history.map(m => ({ role: m.role, content: m.content })),
    { role: 'user', content: userMessage }
  ];

  await sessionStore.addMessage(agentId, 'user', userMessage);

  const tools = getToolsForAgent(agentId);
  let continueLoop = true;
  let fullResponse = '';

  while (continueLoop) {
    continueLoop = false;
    
    try {
      const streamParams = {
        model: 'claude-sonnet-4-20250514',
        max_tokens: 4096,
        system: persona.systemPrompt,
        messages,
        stream: true
      };

      if (tools.length > 0) {
        streamParams.tools = tools;
      }

      const stream = await client.messages.stream(streamParams);

      let currentToolUse = null;
      let toolInputJson = '';

      for await (const event of stream) {
        if (event.type === 'content_block_start') {
          if (event.content_block.type === 'tool_use') {
            currentToolUse = {
              id: event.content_block.id,
              name: event.content_block.name
            };
            toolInputJson = '';
            yield { 
              type: 'tool_start', 
              tool: event.content_block.name,
              display: getToolDisplayName(event.content_block.name)
            };
          }
        } else if (event.type === 'content_block_delta') {
          if (event.delta.type === 'text_delta') {
            fullResponse += event.delta.text;
            yield { type: 'text', text: event.delta.text };
          } else if (event.delta.type === 'input_json_delta') {
            toolInputJson += event.delta.partial_json;
          }
        } else if (event.type === 'content_block_stop') {
          if (currentToolUse) {
            const toolInput = toolInputJson ? JSON.parse(toolInputJson) : {};
            yield { 
              type: 'tool_end', 
              tool: currentToolUse.name,
              input: toolInput
            };

            const toolResult = await executeToolCall(currentToolUse.name, toolInput);
            
            messages.push({
              role: 'assistant',
              content: [{
                type: 'tool_use',
                id: currentToolUse.id,
                name: currentToolUse.name,
                input: toolInput
              }]
            });
            
            messages.push({
              role: 'user',
              content: [{
                type: 'tool_result',
                tool_use_id: currentToolUse.id,
                content: JSON.stringify(toolResult)
              }]
            });

            currentToolUse = null;
            continueLoop = true;
          }
        } else if (event.type === 'message_stop') {
          if (!continueLoop) {
            yield { type: 'done' };
          }
        }
      }
    } catch (error) {
      yield { type: 'error', error: error.message };
      return;
    }
  }

  if (fullResponse) {
    await sessionStore.addMessage(agentId, 'assistant', fullResponse);
  }
}

export function getAgents() {
  return personaLoader.getAllAgents();
}

export function getAgentHistory(agentId) {
  return sessionStore.getConversationHistory(agentId);
}

export async function clearAgentSession(agentId) {
  await sessionStore.clearSession(agentId);
}
