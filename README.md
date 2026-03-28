# Agent Orchestration Setup (tmux + Claude Code)

RTS-inspired multi-agent orchestration — manage multiple Claude Code agents across repos
without full context switches, using tmux as the orchestration layer.

Multi-platform: macOS, Windows (MSYS2), Linux.

## Install

Each platform has its own directory with platform-specific configs:

### macOS

```bash
brew install tmux fzf
cd /path/to/agent-orchestration
./mac/install.sh
```

### Windows (MSYS2)

1. Install [MSYS2](https://www.msys2.org/) (default: `C:\msys64`)
2. In MSYS2 terminal:

```bash
pacman -S tmux mingw-w64-x86_64-fzf
cd /c/projects/agent-orchestration
./windows/install.sh
```

> **Note:** MSYS2's `$HOME` is `/home/<user>` (`C:\msys64\home\<user>`), not `/c/Users/<user>`.

### Linux

```bash
sudo apt install tmux fzf   # or your distro's package manager
cd /path/to/agent-orchestration
./linux/install.sh           # not yet implemented — see linux/README.md
```

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) must be installed and on `PATH` for all platforms.

## Usage

### Start a session

```bash
work            # attach/create "agents" session
work query      # attach/create "query" session
```

### Spawn agents

| Hotkey | Action |
|---|---|
| `ctrl+a → N` | Fuzzy repo picker → opens claude in new background window |
| `ctrl+a → n` | Prompt for path → opens claude there |

### Monitor agents

| Command / Hotkey | Action |
|---|---|
| `v 2` | Quick peek at agent 2 (floating overlay, last 30 lines) |
| `ctrl+a → A` | APM dashboard popup |
| Status bar | Grey = idle, Green = running, Red = needs input |

### Send commands without switching

```bash
q 2 use JWT                       # queue message to agent 2
q 2 "can you check the tests?"   # quote if message has ? ! * etc.
q 2 1                             # approve (no Enter — instant select)
```

### Navigation

| Hotkey | Action |
|---|---|
| `ctrl+a → 1..9` | Jump to window N |
| `ctrl+a → w` | Window list with live preview |
| `ctrl+a → s` | Session tree |
| `ctrl+a → \|` | Split pane horizontal |
| `ctrl+a → -` | Split pane vertical |
| `ctrl+a → d` | Detach (leave running in background) |
| `ctrl+a → r` | Reload tmux config |
| `ctrl+a → ,` | Rename current window |

## APM Tracking

The status bar shows a rolling 60-second count: `42a/7h` = 42 agent actions, 7 human actions.

`ctrl+a → A` opens the full dashboard with today's totals, avg response time, and active agent count.

### What gets tracked

| Event | Logged as |
|---|---|
| Agent tool use | `agent` |
| Agent waiting for input | `wait` |
| `q` command sent | `human-q` |
| `v` peek | `human-v` |
| Window switch | `switch` |
| Fuzzy picker / new window / splits | `tmux-*` |

Log lives at `~/.tmux/apm.log`, auto-pruned to 24h.

## Claude Code Hooks

The `claude-settings.json` configures two hooks:

- **Stop** — sets `@waiting` flag (turns status bar red), fires bell, logs `wait`
- **PreToolUse** — clears `@waiting` flag, logs `agent` tool use

## Files

```
├── CLAUDE.md.template       # scaffold template for per-repo CLAUDE.md
├── IDEAS.md                 # roadmap & feature ideas
├── mac/
│   ├── install.sh           # symlinks into ~/
│   ├── zshrc                # shell functions (zsh)
│   ├── tmux.conf
│   ├── claude-settings.json
│   └── tmux-scripts/        # macOS-specific (osascript, BSD date)
├── windows/
│   ├── install.sh           # copies into MSYS2 $HOME
│   ├── bashrc               # shell functions (bash)
│   ├── tmux.conf
│   ├── claude-settings.json
│   └── tmux-scripts/        # Windows-specific (PowerShell toast, GNU date)
└── linux/
    └── README.md            # placeholder — not yet implemented
```

## Platform differences

| | macOS | Windows (MSYS2) | Linux |
|---|---|---|---|
| Shell | zsh | bash | bash |
| Home | `~/` | `/home/<user>` (MSYS2) | `~/` |
| Repo dir | `~/garner/repos` | `/c/projects` | configurable |
| `date` | BSD (`-v0H`) | GNU (`-d "today..."`) | GNU |
| `read` key | `-rk1` (zsh) | `-rsn1` (bash) | `-rsn1` |
| Notifications | `osascript` | PowerShell toast | `notify-send` |
| Idle check | `zsh` process | `bash` process | `bash` process |
