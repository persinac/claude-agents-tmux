/**
 * Pixel Dashboard Bridge Server
 *
 * Polls tmux state and JSONL transcripts, sends events to the
 * pixel-agents webview UI over WebSocket.
 *
 * Events emitted match the pixel-agents postMessage protocol:
 *   agentCreated, agentClosed, agentStatus, agentToolStart, agentToolDone, agentToolsClear
 */

import { WebSocketServer } from 'ws';
import { execSync } from 'child_process';
import { readFileSync, existsSync, readdirSync, statSync } from 'fs';
import { join, basename } from 'path';
import { homedir } from 'os';

const PORT = parseInt(process.env.PORT || '8420', 10);
const POLL_MS = 500;
const TMUX_SESSION = process.env.TMUX_SESSION || 'agents';

// Platform detection
const isWindows = process.platform === 'win32';
const TMUX_BIN = isWindows ? 'C:\\msys64\\usr\\bin\\tmux.exe' : 'tmux';

// Claude transcript directory
const HOME = homedir();
const CLAUDE_PROJECTS_DIR = join(HOME, '.claude', 'projects');

// ── State ────────────────────────────────────────────────────────

/** @type {Map<number, {name: string, waiting: string, path: string}>} */
const agents = new Map();

/** @type {Map<string, {offset: number, activeTools: Set<string>}>} */
const transcriptState = new Map();

/** @type {Set<import('ws').WebSocket>} */
const clients = new Set();

let nextToolId = 1;

// ── tmux polling ─────────────────────────────────────────────────

function tmuxListWindows() {
  try {
    const out = execSync(
      `"${TMUX_BIN}" list-windows -t "${TMUX_SESSION}" -F "#{window_index}|#{window_name}|#{@waiting}|#{pane_current_path}|#{pane_current_command}"`,
      { encoding: 'utf8', timeout: 2000 }
    ).trim();
    return out.split('\n').filter(Boolean).map(line => {
      const [index, name, waiting, path, command] = line.split('|');
      return { index: parseInt(index, 10), name, waiting, path, command };
    });
  } catch {
    return [];
  }
}

function isClaude(command) {
  return command && command.toLowerCase().includes('claude');
}

function waitingToStatus(waiting) {
  if (waiting === '1') return 'permission';  // needs input → permission bubble
  if (waiting === '2') return 'waiting';     // idle/done → waiting bubble
  return 'active';                            // 0 or unset → active
}

// ── Broadcast ────────────────────────────────────────────────────

function broadcast(msg) {
  const data = JSON.stringify(msg);
  for (const ws of clients) {
    if (ws.readyState === 1) ws.send(data);
  }
}

// ── JSONL transcript reading ─────────────────────────────────────

function findTranscriptFile(agentPath) {
  // Claude transcripts live at ~/.claude/projects/<hash>/<session>.jsonl
  // The hash is derived from the project path
  if (!existsSync(CLAUDE_PROJECTS_DIR)) return null;

  // Normalize the path to create the hash Claude uses
  const normalized = agentPath
    .replace(/\\/g, '-')
    .replace(/\//g, '-')
    .replace(/:/g, '-');

  // Look for a matching project directory
  try {
    const dirs = readdirSync(CLAUDE_PROJECTS_DIR);
    for (const dir of dirs) {
      // Check if this dir matches our agent's path pattern
      if (normalized.includes(dir) || dir.includes(normalized.slice(-30))) {
        const projectDir = join(CLAUDE_PROJECTS_DIR, dir);
        const stat = statSync(projectDir);
        if (!stat.isDirectory()) continue;

        // Find the most recent .jsonl file
        const files = readdirSync(projectDir)
          .filter(f => f.endsWith('.jsonl'))
          .map(f => ({
            name: f,
            mtime: statSync(join(projectDir, f)).mtimeMs
          }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          return join(projectDir, files[0].name);
        }
      }
    }
  } catch {
    // ignore
  }
  return null;
}

function readNewLines(filePath) {
  if (!existsSync(filePath)) return [];

  let state = transcriptState.get(filePath);
  if (!state) {
    state = { offset: 0, activeTools: new Set() };
    transcriptState.set(filePath, state);
  }

  try {
    const content = readFileSync(filePath, 'utf8');
    if (content.length <= state.offset) return [];

    const newContent = content.slice(state.offset);
    state.offset = content.length;

    const lines = newContent.split('\n').filter(Boolean);
    const records = [];
    for (const line of lines) {
      try {
        records.push(JSON.parse(line));
      } catch {
        // partial line, skip
      }
    }
    return records;
  } catch {
    return [];
  }
}

function processTranscriptRecords(agentId, records) {
  for (const record of records) {
    if (record.type === 'assistant' && record.message?.content) {
      const content = Array.isArray(record.message.content)
        ? record.message.content
        : [];

      for (const block of content) {
        if (block.type === 'tool_use') {
          const toolId = block.id || `tool_${nextToolId++}`;
          const toolName = block.name || 'unknown';
          const input = block.input || {};

          // Build status string
          let status = toolName;
          if (toolName === 'Read' && input.file_path) {
            status = `Reading ${basename(input.file_path)}`;
          } else if (toolName === 'Write' && input.file_path) {
            status = `Writing ${basename(input.file_path)}`;
          } else if (toolName === 'Edit' && input.file_path) {
            status = `Editing ${basename(input.file_path)}`;
          } else if (toolName === 'Bash' && input.command) {
            status = `Running: ${input.command.slice(0, 30)}`;
          } else if (toolName === 'Grep' && input.pattern) {
            status = `Searching: ${input.pattern.slice(0, 30)}`;
          } else if (toolName === 'Glob' && input.pattern) {
            status = `Finding: ${input.pattern.slice(0, 30)}`;
          }

          broadcast({ type: 'agentToolStart', id: agentId, toolId, status });

          const state = transcriptState.get(`agent_${agentId}`);
          if (state) state.activeTools.add(toolId);
        }
      }
    }

    if (record.type === 'user' && record.message?.content) {
      const content = Array.isArray(record.message.content)
        ? record.message.content
        : [];

      for (const block of content) {
        if (block.type === 'tool_result' && block.tool_use_id) {
          broadcast({ type: 'agentToolDone', id: agentId, toolId: block.tool_use_id });
        }
      }
    }
  }
}

// ── Main poll loop ───────────────────────────────────────────────

function poll() {
  const windows = tmuxListWindows();
  const currentIds = new Set();

  for (const win of windows) {
    if (!isClaude(win.command)) continue;

    const id = win.index;
    currentIds.add(id);

    const existing = agents.get(id);
    const status = waitingToStatus(win.waiting);

    if (!existing) {
      // New agent
      agents.set(id, { name: win.name, waiting: win.waiting, path: win.path });
      broadcast({ type: 'agentCreated', id, folderName: win.name });
      broadcast({ type: 'agentStatus', id, status });
    } else {
      // Status changed?
      if (existing.waiting !== win.waiting) {
        existing.waiting = win.waiting;
        broadcast({ type: 'agentStatus', id, status });
      }

      // Name changed?
      if (existing.name !== win.name) {
        existing.name = win.name;
      }
    }

    // Read JSONL transcripts for tool-level events
    const transcriptFile = findTranscriptFile(win.path);
    if (transcriptFile) {
      const records = readNewLines(transcriptFile);
      if (records.length > 0) {
        processTranscriptRecords(id, records);
      }
    }
  }

  // Remove closed agents
  for (const [id] of agents) {
    if (!currentIds.has(id)) {
      agents.delete(id);
      broadcast({ type: 'agentClosed', id });
    }
  }
}

// ── WebSocket server ─────────────────────────────────────────────

const wss = new WebSocketServer({ port: PORT });

wss.on('connection', (ws) => {
  clients.add(ws);
  console.log(`Client connected (${clients.size} total)`);

  // Send current state to new client
  for (const [id, agent] of agents) {
    ws.send(JSON.stringify({ type: 'agentCreated', id, folderName: agent.name }));
    ws.send(JSON.stringify({
      type: 'agentStatus',
      id,
      status: waitingToStatus(agent.waiting)
    }));
  }

  ws.on('message', (raw) => {
    // Handle messages from webview (saveAgentSeats, saveLayout, etc.)
    try {
      const msg = JSON.parse(raw.toString());
      console.log('[Webview→Server]', msg.type);
    } catch {
      // ignore
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    console.log(`Client disconnected (${clients.size} total)`);
  });
});

// ── Start ────────────────────────────────────────────────────────

console.log(`Pixel Dashboard bridge server`);
console.log(`  WebSocket: ws://localhost:${PORT}`);
console.log(`  Polling tmux session: "${TMUX_SESSION}" every ${POLL_MS}ms`);
console.log(`  Transcripts: ${CLAUDE_PROJECTS_DIR}`);

setInterval(poll, POLL_MS);
poll(); // initial poll
