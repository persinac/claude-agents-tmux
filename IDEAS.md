# Ideas & Roadmap

## High impact — low effort

1. ~~**Windows toast notifications**~~ — removed; red status bar indicator (item 3) is sufficient
2. **Batch approve/reject** — done: `qa` function (e.g., `qa 1` to approve all waiting agents)
3. **Wait duration in status bar** — done: three-state color system (green=working, grey=idle, red+timer=needs input) via `PreToolUse`, `Stop`, and `Notification` hooks
4. **CLAUDE.md files per repo** — done: `CLAUDE.md.template` + `claude-init` command to scaffold

## Medium effort — multiplier effects

5. **Session templates** — predefined layouts for common workflows (e.g., `work-stack frontend backend tests` spins up 3 agents in specific repos). One command to set up a whole workstream
6. **Git worktree integration** — auto-create worktrees when spawning agents in the same repo, so two agents can work on different branches without conflicts
7. **Agent summary on peek** — enhance `v()` to parse the last Claude output and show a one-line status (e.g., "editing src/auth.ts", "waiting: approve file write?", "running tests") instead of raw terminal output
8. **Stuck agent detection** — if an agent's been "running" (green) for >10min with no tool use logged, flag it yellow. Means it's probably hung or in a loop

## Bigger bets

9. **Agent handoff / chaining** — when agent 2 finishes, auto-send its summary to agent 3. Pipeline workflows like: agent 1 writes code → agent 2 reviews → agent 3 runs tests
10. **Searchable history** — structured log (JSON instead of flat APM log) capturing what each agent worked on, which files it touched, outcome. Queryable with `jq`
11. **Cost/token dashboard** — track token usage per agent per session alongside APM
12. **Auto-routing** — when an agent goes red, automatically `v` it in a small persistent pane at the bottom, so you see what it needs without manual peeking
