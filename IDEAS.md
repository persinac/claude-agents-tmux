# Ideas & Roadmap

## High impact — low effort

1. ~~**Windows toast notifications**~~ — removed; red status bar indicator (item 3) is sufficient
2. **Batch approve/reject** — done: `qa` function (e.g., `qa 1` to approve all waiting agents)
3. **Wait duration in status bar** — done: three-state color system (green=working, grey=idle, red+timer=needs input) via `PreToolUse`, `Stop`, and `Notification` hooks
4. **CLAUDE.md files per repo** — done: `CLAUDE.md.template` + `claude-init` command to scaffold

## Medium effort — multiplier effects

| # | Priority | Idea | Status |
|---|----------|------|--------|
| 5 | 8 | **Session templates** — predefined layouts for common workflows (e.g., `work-stack frontend backend tests`). One command to set up a whole workstream | |
| 6 | 1 | **Git worktree integration** — auto-create worktrees when spawning agents in the same repo, so two agents can work on different branches without conflicts | done |
| 7 | 5 | **Agent summary on peek** — enhance `v()` to parse the last Claude output and show a one-line status instead of raw terminal output | |
| 8 | 5 | **Stuck agent detection** — if an agent's been "running" (green) for >10min with no tool use logged, flag it yellow | |
| 9 | — | **Agent-to-agent messaging** — `/msg <slot> <message>` slash command + `agent-send.sh` script | done |

## Bigger bets

| # | Priority | Idea | Status |
|---|----------|------|--------|
| 10 | 3 | **Agent handoff / chaining** — when agent 2 finishes, auto-send its summary to agent 3. Pipeline: write → review → test | |
| 11 | 2 | **Searchable history** — structured log (JSON instead of flat APM log) capturing what each agent worked on, which files it touched, outcome. Queryable with `jq` | |
| 12 | 5 | **Cost/token dashboard** — track token usage per agent per session alongside APM | |
| 13 | 8 | **Auto-routing** — when an agent goes red, automatically `v` it in a small persistent pane at the bottom | |
| 14 | 2 | **Pixel agents dashboard** — fork [pixel-agents](https://github.com/pablodelucca/pixel-agents) React webview into a standalone Electron/web app. Replace VS Code postMessage with WebSocket fed by tmux hook data. Animated pixel art characters show agent state (typing/reading/waiting/idle) in a fun office visualization. Source: `webview-ui/` in the pixel-agents repo. | done |
| 15 | 2 | **Agent awareness** — agents should know about other running agents (window slot, repo, branch, status) and be able to use `/msg` to request info from them. Could be a CLAUDE.md snippet or a hook that injects context on session start. | |
