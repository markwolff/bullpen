# Bullpen — Product Vision & Requirements

**Activity Monitor for AI Agents**

A native macOS app that gives developers ambient, real-time visibility into what their AI coding agents are doing, using a charming pixel-art office metaphor.

---

## 1. Executive Summary

Bullpen is a macOS menu bar app that monitors AI coding agent activity and visualizes it as animated pixel-art sprites working in a cozy 2D office. It reads Claude Code and Codex CLI log files, maps agent tool calls to visual behaviors, and gives developers a glanceable, ambient view of what their agents are doing — without requiring them to tab between terminal windows. No tool like this exists today.

---

## 2. Problem Statement

### The Pain

Developers increasingly run 2-5 AI coding agents simultaneously — one refactoring a module, another writing tests, a third fixing a bug. Today, managing these agents means blindly tabbing between terminal windows with zero visibility into collective progress.

### Who Feels It

- **Solo developers** running parallel Claude Code sessions across repos
- **Team leads** coordinating agent-assisted work across a team
- **Vibe coders** who want to understand what AI is generating without reading every diff

### Why Now

- The "multi-agent" pattern is mainstream — Claude Code, Codex CLI, Cursor, and Aider are used concurrently
- The "manager of agents" is an emerging developer archetype with zero tooling
- AI-generated code volume is increasing faster than developer review capacity

### Current Alternatives and Their Gaps

| Tool | What It Does | Gap |
|------|-------------|-----|
| Raw terminal windows | See streaming text per agent | No unified view, no ambient monitoring, high cognitive load |
| LangSmith / LangFuse | LLM call tracing and debugging | Developer debugging tool, not ambient display; requires instrumentation |
| RunCat | CPU usage as a running cat in menu bar | Single metric, no agent awareness |
| Devin | Screen-share-style agent viewer | Proprietary, single agent only, cloud-only |
| Anthropic Console | Token usage dashboard | Post-hoc, no real-time, no per-agent view |

**The gap**: No tool provides ambient, multi-agent, real-time visualization of AI coding agent activity.

---

## 3. Vision & Principles

### Vision

Make AI agent activity as visible and intuitive as watching colleagues work in an office. A developer should be able to glance at Bullpen and instantly know: how many agents are active, what each is doing, and whether any need attention.

### Design Principles

1. **Ambient, not demanding** — Low cognitive load. Bullpen is a background presence, not a foreground application. It should never interrupt or demand attention unless something is wrong.

2. **Delightful, not clinical** — Pixel-art charm over sterile dashboards. The office metaphor makes agent activity approachable and fun to watch.

3. **Battery-conscious** — Tiered frame rates based on visibility. A floating window app must be a good citizen of system resources.

4. **Agent-agnostic** — Support any agent via pluggable log readers. Start with Claude Code and Codex, design for extensibility.

5. **Privacy-first** — All data stays local. No network calls, no telemetry without explicit opt-in, no cloud dependency. Open source.

---

## 4. Target Users & Personas

### Persona 1: The Multi-Agent Power User

**Profile**: Senior developer running 3-4 Claude Code sessions across different repos/branches.
**Workflow context**: Has multiple terminal tabs, each with a Claude Code session working on different tasks (refactoring, test writing, bug fixing). Regularly forgets which terminal is doing what.
**Need**: Glanceable overview of all active agents. Wants to know when one finishes or hits an error without checking each terminal.

### Persona 2: The Vibe Coder

**Profile**: Developer using AI agents heavily for code generation. Comfortable directing agents but doesn't read every line of output.
**Workflow context**: Fires off Claude Code with a broad prompt, then works on something else. Wants a passive indicator of progress.
**Need**: Ambient awareness of agent progress. Visual confirmation that agents are working, not stuck.

### Persona 3: The Team Lead

**Profile**: Engineering lead whose team uses AI agents for development. Wants visibility into collective agent activity.
**Workflow context**: Team members run agents independently. No shared dashboard shows overall agent utilization.
**Need**: Team-level view of all agents across the team (future feature). For now, personal visibility is the entry point.

### Persona 4: The Curious Observer

**Profile**: Developer who enjoys desktop pets, ambient displays, and fun developer tools. Attracted to Bullpen's aesthetic before its utility.
**Workflow context**: Wants something delightful on their desktop. The office metaphor is the hook.
**Need**: A charming, well-crafted macOS experience. Utility is secondary to delight for initial adoption.

---

## 5. Product Overview

### What Bullpen Is

A native macOS menu bar application that:
1. Watches agent log directories for activity
2. Parses log events into agent states (thinking, coding, reading, running commands, etc.)
3. Renders agents as animated pixel-art sprites in a 2D office scene
4. Displays the scene in a floating, always-on-top window
5. Shows thought bubbles with current agent activity
6. Provides a detail panel on click

### How It Works

```
┌─────────────────────────────────────────────────────┐
│                    Log Files                         │
│  ~/.claude/projects/*/sessions/*.jsonl  (Claude)     │
│  ~/.codex/history/*.json               (Codex)      │
└───────────────┬─────────────────────┬───────────────┘
                │                     │
                v                     v
        ┌───────────────┐    ┌───────────────┐
        │ ClaudeCode    │    │ Codex         │
        │ LogReader     │    │ LogReader     │
        └───────┬───────┘    └───────┬───────┘
                │                     │
                v                     v
        ┌─────────────────────────────────────┐
        │       AgentMonitorService           │
        │  - Discovers active sessions        │
        │  - Maintains agent state machines   │
        │  - Emits state change events        │
        └───────────────┬─────────────────────┘
                        │
                        v
        ┌─────────────────────────────────────┐
        │         OfficeScene (SpriteKit)      │
        │  - Agent sprites at desks           │
        │  - Thought bubbles                  │
        │  - Status indicators                │
        │  - Ambient animations               │
        └─────────────────────────────────────┘
```

### Developer Experience Walkthrough

**Minute 0**: Install via `brew install --cask bullpen` or download DMG.

**Minute 1**: Launch Bullpen. A small office icon appears in the menu bar. A floating window shows an empty office with desks.

**Minute 2**: Open a terminal and start a Claude Code session: `claude "Refactor the auth module"`. Within seconds, a sprite appears at a desk in Bullpen. Its thought bubble shows "Reading src/auth/...". The sprite is leaned forward, reading.

**Minute 3**: Start a second Claude Code session in another terminal. A second sprite appears at the next desk. Now the office has two agents working.

**Minute 4**: The first agent starts writing code. Its sprite switches to a rapid-typing animation. The thought bubble updates: "Editing src/auth/middleware.ts". The monitor on its desk glows green.

**Minute 5**: The second agent encounters an error. Its sprite does a facepalm animation. A red exclamation mark appears above its head. Its monitor flickers red. The developer glances at Bullpen, sees the error, and switches to that terminal to investigate.

**Ongoing**: Bullpen stays in the background. The developer glances at it periodically — a quick scan tells them: "Two agents active, both coding, no errors." They continue their own work with ambient confidence.

---

## 6. Core Features — V1

### 6.1 Agent Discovery

Automatically detect running AI coding agent sessions by watching known log directories.

**Claude Code**:
- Watch `~/.claude/projects/*/sessions/` for new `.jsonl` files
- Each file represents one session (UUID filename)
- New file creation = new agent session detected
- File modification = agent is active

**Codex CLI**:
- Watch `~/.codex/history/` for new `.json` files
- Each file is a complete session (timestamp filename)
- File creation = new session

**Detection mechanism**: FSEvents-based file watcher (macOS native, zero polling overhead).

**Acceptance criteria**:
- New agent session detected within 2 seconds of first log write
- Agent removal detected within 30 seconds of session ending (no new writes)
- Support at least 8 concurrent agents

### 6.2 Log Parsing

Parse agent log files into structured events that drive state changes.

**Claude Code JSONL format** (one JSON object per line):
```jsonc
{
  "type": "assistant",
  "message": {
    "role": "assistant",
    "content": [
      {
        "type": "tool_use",
        "name": "Read",          // Tool name drives state
        "input": {
          "file_path": "/src/auth/middleware.ts"
        }
      }
    ],
    "usage": {
      "input_tokens": 1234,
      "output_tokens": 567
    }
  },
  "timestamp": "2026-03-15T14:30:00Z"
}
```

**Tool-to-state mapping**:

| Tool Call | Agent State |
|-----------|------------|
| `Read`, `Glob`, `Grep` | readingFiles |
| `Write`, `Edit` | writingCode |
| `Bash` | runningCommand |
| No tool (text response) | thinking |
| Error in tool_result | error |
| `stop_reason: "end_turn"` | finished |
| No activity for 30s | idle |

**Codex CLI JSON format**:
```jsonc
{
  "items": [
    {
      "role": "assistant",
      "functionCalls": [
        {
          "name": "shell",
          "arguments": { "command": ["npm", "test"] },
          "output": "..."
        }
      ]
    }
  ]
}
```

**Codex tool mapping**: `file_read` → readingFiles, `file_write`/`file_edit` → writingCode, `shell` → runningCommand.

### 6.3 Office Scene

A 2D pixel-art office rendered via SpriteKit in a floating transparent window.

**Perspective**: 3/4 top-down (RPG-style), like Game Dev Tycoon or Stardew Valley.

**Layout**: Two rows of 4 desks (8 max agents). Each desk has a monitor, chair, and personal decorations. Desks are assigned to agents in discovery order.

**Scene dimensions**: 1024x768 base resolution, scaled for Retina.

**Ambient elements**:
- Wall clock with ticking second hand
- Potted plants with gentle sway (2-frame, 3-second cycle)
- Coffee mugs with steam particles (tiny white wisps rising)
- Window with simulated daylight (color shifts slowly)
- Empty desks have powered-off monitors

### 6.4 Sprite Animations

Each agent is a 32x48 pixel character sprite using pixel art with `.nearest` texture filtering.

**Animation states** (2-8 frames each, loop continuously):

| State | Animation | Frame Count | FPS |
|-------|-----------|-------------|-----|
| idle | Gentle bob, occasional blink, sips coffee | 4 | 0.5 |
| thinking | Leans back, hand on chin, looks up | 4 | 0.5 |
| writingCode | Seated, rapid hand movement on keyboard | 2 | 8 |
| readingFiles | Leaned forward, slow head movement | 3 | 0.3 |
| runningCommand | Watching screen intently, still | 2 | 1 |
| searching | Looking left and right | 4 | 1 |
| waitingForInput | Tapping foot, drumming fingers | 4 | 2 |
| error | Recoil/facepalm, hands on head | 2 | 2 |
| finished | Stands up, stretches, steps back | 4 | 1 |

**Transitions**: Never snap between states. Blend with a 0.3s transition animation. Error transitions are instant (jarring = intentional).

### 6.5 Thought Bubbles

Comic-book-style speech bubbles above each agent showing current activity.

**Content**: Shows the current tool call and its primary argument:
- "Reading src/auth/middleware.ts"
- "Writing src/models/User.ts"
- "Running npm test"
- "Searching for 'handleAuth'"
- "Thinking..."
- "Error in Bash"

**Behavior**: Updates on every tool call. Fades after 10s of no new activity. Scrolls horizontally for long file paths. Maximum width: 200px.

### 6.6 Status Indicators

Colored dot above each agent's desk, always visible.

| State | Color | Shape |
|-------|-------|-------|
| idle | Gray (#A0A0A0) | Circle |
| thinking | Yellow (#F0C040) | Circle |
| writingCode | Green (#50C878) | Circle |
| readingFiles | Cyan (#60B0D0) | Circle |
| runningCommand | Orange (#E89040) | Circle |
| error | Red (#E05050) | Square |
| finished | Dim gray (#707070) | Circle |

Pulse animation on state change. Steady glow during sustained activity.

### 6.7 Menu Bar Presence

`NSStatusItem` with:
- Icon: small office building or pixel character
- Badge: count of active agents (e.g., "3")
- Click: toggle floating window visibility
- Right-click: menu with Preferences, Quit

### 6.8 Detail Popover

Click an agent sprite to show a popover with:
- Agent name (auto-generated: "Agent 1" or session ID)
- Agent type (Claude Code / Codex)
- Current state and duration in state
- Current file/tool being operated on
- Session start time and duration
- Token usage (input/output tokens from log)
- Last 5 tool calls (mini timeline)
- Working directory path

---

## 7. Technical Architecture

### Platform Requirements
- macOS 15+ (Sequoia)
- Swift 6, SwiftUI, SpriteKit
- No external dependencies for core (Sparkle for updates)

### Application Architecture

```
BullpenApp (@main SwiftUI App)
├── AppDelegate (NSApplicationDelegateAdaptor)
│   ├── NSStatusItem (menu bar)
│   ├── NSWindow (floating, transparent, borderless)
│   └── SKView → OfficeScene
├── Services/
│   ├── AgentMonitorService (ObservableObject)
│   │   ├── LogWatcher (FSEvents)
│   │   ├── ClaudeCodeLogReader
│   │   └── CodexLogReader
│   └── AgentStateManager
├── Models/
│   ├── AgentInfo (id, type, state, session)
│   ├── AgentState (enum: 9 states)
│   └── AgentActivity (tool call data)
└── SpriteWorld/
    ├── OfficeScene (SKScene)
    ├── AgentSprite (SKSpriteNode)
    ├── ThoughtBubble (SKNode)
    └── OfficeLayout (desk positions)
```

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rendering engine | SpriteKit | Built-in 2D game engine, perfect for sprite animation, texture atlases, particles |
| Window type | Floating borderless NSWindow | Stays above other windows, transparent background, visible on all Spaces |
| Dock presence | LSUIElement=true | No dock icon — menu bar only. Standard for ambient utility apps |
| Log monitoring | FSEvents | macOS-native, zero-polling, battery-efficient file watching |
| Pixel art rendering | .nearest texture filtering | Preserves crisp pixel edges at any scale |
| Frame rate | Tiered: 30/10/0 FPS | Active: 30fps, inactive: 10fps, occluded: paused |
| Data persistence | None in V1 | Bullpen is stateless — reads logs in real time, no database |

### Window Configuration

```swift
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 512, height: 384),
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
window.level = .floating
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = false
window.collectionBehavior = [.canJoinAllSpaces, .stationary]
window.isMovableByWindowBackground = true
```

### Performance Budget

| Metric | Target | Measurement |
|--------|--------|-------------|
| CPU (idle, 2 agents) | < 2% | Instruments |
| CPU (active, 8 agents) | < 5% | Instruments |
| Memory | < 50 MB | Instruments |
| GPU (idle) | < 1% | Instruments |
| Energy impact | "Low" in Activity Monitor | macOS Energy gauge |

Achieved via:
- `preferredFramesPerSecond = 30` when active, `10` when app inactive, `isPaused = true` when occluded
- `NSWindow.occlusionState` and `NSApplication.didResignActiveNotification` observers
- Texture atlases for batched draw calls
- `ignoresSiblingOrder = true` for SpriteKit draw call optimization
- Pre-built `SKAction` sequences (no per-frame allocations)

---

## 8. Agent State Model

### State Machine

```
                    ┌──────────┐
         ┌─────────│   idle   │←────────────┐
         │         └────┬─────┘             │
         │              │ tool_use          │ 30s timeout
         v              v                   │
    ┌─────────┐   ┌──────────┐        ┌─────────┐
    │thinking │──→│writingCode│───────→│finished │
    └─────────┘   └──────────┘        └─────────┘
         │              │                   ↑
         │              v                   │
         │        ┌──────────┐              │
         ├───────→│readingFi.│──────────────┤
         │        └──────────┘              │
         │              │                   │
         │              v                   │
         │        ┌──────────┐              │
         ├───────→│runningCmd│──────────────┤
         │        └──────────┘              │
         │              │                   │
         │              v                   │
         │        ┌──────────┐              │
         ├───────→│searching │──────────────┤
         │        └──────────┘              │
         │                                  │
         │        ┌──────────┐              │
         └───────→│  error   │──────────────┘
                  └──────────┘
```

Any state can transition to `error` on error events, or to `idle` on timeout.

### State Detection Logic

```swift
func determineState(from event: LogEvent) -> AgentState {
    switch event {
    case .toolUse(let tool, _):
        switch tool {
        case "Read", "Glob", "Grep":     return .readingFiles
        case "Write", "Edit":            return .writingCode
        case "Bash":                     return .runningCommand
        case "WebSearch", "WebFetch":    return .searching
        default:                         return .thinking
        }
    case .assistantText:                 return .thinking
    case .toolResult(_, let hasError):
        return hasError ? .error : currentState
    case .endTurn:                       return .finished
    case .timeout:                       return .idle
    }
}
```

---

## 9. Visual Design Direction

### Color Palette

**Background / Environment (warm, muted)**:
| Element | Hex | Usage |
|---------|-----|-------|
| Walls | #EAE6DF | Warm off-white background |
| Floor | #C4B6A0 | Warm tan/wood |
| Floor grain | #A89882 | Darker wood accents |
| Desk surface | #8B6544 | Medium brown |
| Dark wood | #6B4A30 | Desk accents |
| Metal/tech | #5A6670 | Monitor frames, chair legs |
| Plants | #6B8F4E | Muted sage green |
| Lamp light | #D4956A | Warm orange accent |
| Screen glow | #7BA3C4 | Soft blue |
| Shadows | #2D2D3D | Warm dark (never pure black) |

**Agent Status Colors (saturated for readability)**:
| State | Color | Hex |
|-------|-------|-----|
| idle | Neutral gray | #A0A0A0 |
| thinking | Warm gold | #F0C040 |
| writingCode | Emerald | #50C878 |
| readingFiles | Soft cyan | #60B0D0 |
| runningCommand | Orange | #E89040 |
| searching | Lavender | #B080D0 |
| waitingForInput | Medium blue | #6090D0 |
| error | Soft red | #E05050 |
| finished | Dim gray | #707070 |

**Monitor Screen Glow** (subtle radial glow around each desk's monitor):
- Writing code: green glow (#50C878 at 15% opacity)
- Running command: amber glow (#E89040 at 10% opacity)
- Idle: blue glow (#6090D0 at 8% opacity)
- Error: red flicker

### Agent Differentiation

| Agent Type | Visual Cue |
|-----------|------------|
| Claude Code | Orange-tinted character, Anthropic logo on desk |
| Codex CLI | Blue-tinted character, OpenAI logo on desk |
| Future agents | Distinct character colors and desk decorations |

### Art Style

- Pixel art, 32x48 character sprites, 16x16 or 32x32 tiles for furniture
- `.nearest` texture filtering for crisp pixel edges on Retina displays
- Sprite sheets in texture atlases for batched rendering
- Recommended asset source: LimeZu's Modern Interiors tileset (itch.io) for office furniture and environment

### Particle Effects

| State | Effect |
|-------|--------|
| thinking | Tiny sparkles drifting upward from head |
| error | Red sparks near desk |
| finished | Brief confetti burst |
| idle (long) | ZZZ particles floating upward |
| coffee mug | Small white wisps (always, ambient) |

---

## 10. Scope & Phasing

### V1 — MVP

| Feature | Included | Notes |
|---------|----------|-------|
| Claude Code log reader | Yes | JSONL parsing from ~/.claude/ |
| Codex CLI log reader | Yes | JSON parsing from ~/.codex/ |
| Office scene (up to 8 agents) | Yes | 3/4 perspective, two rows of desks |
| 9 agent states with animations | Yes | Placeholder sprites initially |
| Thought bubbles | Yes | Current tool + file |
| Status indicator dots | Yes | Colored, pulsing |
| Menu bar presence | Yes | Icon + agent count |
| Detail popover on click | Yes | Session info, token usage, recent tools |
| Floating transparent window | Yes | All Spaces, draggable |
| Frame rate tiering | Yes | 30/10/paused |

### V1.x — Polish

| Feature | Priority |
|---------|----------|
| Custom pixel art sprites (replace placeholders) | High |
| Ambient office animations (clock, plants, coffee, window light) | High |
| macOS notifications (agent finished, agent error) | High |
| Office cat NPC (wanders between desks) | Medium |
| Configurable window size and position | Medium |
| Multiple office layout themes | Low |
| Sound effects (optional, off by default) | Low |

### V2 — Analytics & Expansion

| Feature | Description |
|---------|-------------|
| Agent metrics dashboard | Tokens used, time per task, error rate, tool call frequency |
| Session timeline view | Waterfall of tool calls with duration bars |
| Additional log readers | Cursor, Aider, Copilot, Cline/Roo Code |
| Multi-machine support | SSH/network log streaming for remote agents |
| Team dashboard | Shared view of all agents across a team |
| MCP integration | Bullpen as an MCP server — agents can query status of other agents |

### Future

| Feature | Description |
|---------|-------------|
| Relay integration | Visualize pipeline execution as agents passing work between desks |
| Sightglass integration | Link agent activity to architecture diagram nodes |
| DORA-style agent metrics | Deployment frequency, error rate, time-to-completion benchmarks |
| Agent comparison | Side-by-side performance comparison of different AI tools |
| Historical playback | Replay past sessions in the office view |

### Explicitly Not in Scope

| Exclusion | Rationale |
|-----------|-----------|
| Interactive agent control | Bullpen is read-only. It never sends commands to agents. |
| Windows/Linux support | macOS native only. SpriteKit is Apple-only. |
| Cloud/SaaS version | Local-only for privacy. Consider web companion in V2. |
| Custom agent frameworks | V1 supports Claude Code + Codex only. Plugin system in V2. |
| IDE extension | Bullpen is standalone. IDE integration deferred. |

---

## 11. Success Metrics

### Adoption

| Metric | Target (V1, 3 months) | Measurement |
|--------|----------------------|-------------|
| Installs | 1,000 | Download count + brew analytics |
| Weekly active users | 500 | Opt-in anonymous analytics |
| GitHub stars | 1,000 (6 months) | GitHub |
| Homebrew formula installs | 500 | Homebrew analytics |

### Quality

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to first agent visible | < 2 minutes from install | Manual testing |
| Agent discovery accuracy | > 95% | Automated tests |
| CPU usage (idle, 2 agents) | < 2% | Instruments profiling |
| Memory usage | < 50 MB | Instruments profiling |
| Crash-free sessions | > 99% | Crash reporting (opt-in) |

### Engagement

| Metric | Target | Measurement |
|--------|--------|-------------|
| Average session duration | > 2 hours (ambient background) | Analytics |
| Return rate (D7) | > 60% | Analytics |
| Detail popover usage | > 30% of sessions | Analytics |

---

## 12. Competitive Landscape

| Dimension | Bullpen | RunCat | LangSmith | Devin | Gather.town | Terminal tabs |
|-----------|---------|--------|-----------|-------|-------------|--------------|
| Ambient visualization | Yes | Partial (single metric) | No | Partial | Yes (human) | No |
| Multi-agent support | Yes (up to 8) | No | Yes (traces) | No (single) | Yes (human) | Manual |
| Real-time | Yes | Yes | Near-real-time | Yes | Yes | Yes |
| Log-based (no instrumentation) | Yes | System metrics | No (requires SDK) | N/A | N/A | N/A |
| Agent-agnostic | Yes (pluggable) | N/A | LangChain only | Devin only | N/A | Any |
| Fun / delightful | Yes (pixel art) | Yes (cat) | No (dashboard) | No | Yes (game) | No |
| Free / open source | Yes | Free | Freemium | Paid | Freemium | Free |
| macOS native | Yes | Yes | Web | Web | Web | Yes |

### Positioning Statement

Bullpen is the only tool that combines ambient, real-time, multi-agent visualization with a delightful user experience. It is to AI coding agents what Activity Monitor is to system processes — a glanceable utility that runs in the background and surfaces what matters.

---

## 13. Distribution & Monetization

### Distribution

| Channel | Method |
|---------|--------|
| Primary | Direct download (DMG) from website |
| Developer channel | `brew install --cask bullpen` |
| Source | GitHub (MIT license) |
| Updates | Sparkle framework (automatic background updates) |

### Technical Requirements

- Apple Developer Program membership ($99/year)
- Developer ID Application certificate for code signing
- Notarization via `xcrun notarytool`
- Hardened runtime with entitlements (non-sandboxed for file system access)
- Universal binary (arm64 + x86_64)

### Pricing Model

**Freemium — generous free tier for adoption, paid for power features**:

| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | Up to 4 agents, 2 log readers (Claude + Codex), all animations, detail popover |
| Pro | $49/year | Up to 16 agents, all log readers, metrics dashboard, notifications, timeline view, custom themes |
| Team | $99/year per seat | Shared team dashboard, agent metrics aggregation, Slack integration |

**Rationale**: Developers adopt tools bottom-up. The free tier must provide genuine, daily value. Pro features target power users who expense annual purchases. Team features target engineering orgs adopting AI agents at scale.

---

## 14. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Claude Code log format changes without notice | High | High | Abstract behind LogReader protocol; version-detect format; community contributions for updates; automated format tests |
| High battery drain from SpriteKit | Medium | High | Tiered frame rates (30/10/0); aggressive occlusion pausing; profile extensively before release; energy impact budget |
| macOS-only limits total addressable market | Medium | Medium | Web-based companion dashboard in V2; position macOS-native as a quality differentiator |
| Sprite art quality affects product perception | Medium | Medium | Commission professional pixel artist early; placeholder sprites are acceptable for beta; aesthetic is core to value prop |
| Privacy concerns about reading agent logs | Low | High | All processing is local; no network calls; no telemetry without opt-in; open source code for auditability |
| Apple notarization / code signing friction | Low | Medium | Budget time for certificate setup; document the process; use Sparkle for updates to avoid re-notarization |
| Log directories require file system access | Low | Medium | Non-sandboxed distribution (not Mac App Store); request only needed TCC permissions |
| Competition from agent vendors (Anthropic/OpenAI build their own monitoring) | Medium | Medium | Stay agent-agnostic; support ALL agents, not just one vendor; community plugin ecosystem |

---

## 15. Cross-Project Synergies

### The Ecosystem

Bullpen is one of three complementary tools:

```
┌─────────┐     ┌─────────┐     ┌───────────┐
│  Relay  │────→│ Bullpen │────→│ Sightglass│
│ Define  │     │ Observe │     │ Understand│
└─────────┘     └─────────┘     └───────────┘
  Orchestrate     Monitor          Visualize
  AI pipelines    agent activity   code architecture
```

### Bullpen + Relay

Relay pipelines emit structured step events (stepStart, stepComplete, stepError). Bullpen can consume these events to visualize pipeline execution: agents at desks passing work items between them, with the pipeline flow visible as a sequence of handoffs.

### Bullpen + Sightglass

Bullpen shows WHAT agents are doing (reading files, writing code). Sightglass shows WHAT THEY BUILT (architecture diagrams). Clicking an agent's current file in Bullpen could highlight the corresponding node in Sightglass, connecting activity to architecture.

### Combined Value Proposition

"Define, Observe, Understand" — a complete AI-assisted development observability stack:
- **Relay** defines structured agent workflows
- **Bullpen** provides real-time ambient monitoring of agent activity
- **Sightglass** maps the resulting code architecture for human understanding

---

## Appendix A: Claude Code Log Schema Reference

### Session File Location
```
~/.claude/projects/<project-hash>/sessions/<session-uuid>.jsonl
```

### JSONL Line Schema
```jsonc
{
  "type": "assistant",           // "user" | "assistant" | "system" | "result"
  "message": {
    "role": "assistant",
    "content": [
      {
        "type": "text",
        "text": "Let me read that file..."
      },
      {
        "type": "tool_use",
        "id": "toolu_abc123",
        "name": "Read",          // Tool name
        "input": {
          "file_path": "/src/auth/middleware.ts"
        }
      }
    ],
    "model": "claude-sonnet-4-20250514",
    "stop_reason": "tool_use",   // "end_turn" | "tool_use" | "max_tokens"
    "usage": {
      "input_tokens": 12345,
      "output_tokens": 678,
      "cache_creation_input_tokens": 0,
      "cache_read_input_tokens": 890
    }
  },
  "timestamp": "2026-03-15T14:30:00Z",
  "sessionId": "uuid-here"
}
```

### Tool Names
`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `TodoRead`, `TodoWrite`, `NotebookEdit`, `mcp__*` (MCP tools)

## Appendix B: Codex CLI Log Schema Reference

### Session File Location
```
~/.codex/history/<timestamp>.json
```

### JSON Schema
```jsonc
{
  "sessionId": "uuid",
  "startTime": "2026-03-15T14:30:00Z",
  "endTime": "2026-03-15T14:45:00Z",
  "model": "o4-mini",
  "provider": "openai",
  "approvalMode": "suggest",
  "cwd": "/path/to/project",
  "items": [
    {
      "role": "user",
      "content": "Fix the login bug"
    },
    {
      "role": "assistant",
      "content": "I'll investigate the login issue...",
      "functionCalls": [
        {
          "name": "file_read",
          "arguments": { "path": "src/auth/login.ts" },
          "output": "..."
        },
        {
          "name": "shell",
          "arguments": { "command": ["npm", "test"] },
          "output": "..."
        }
      ]
    }
  ]
}
```

### Function Names
`shell`, `file_read`, `file_write`, `file_edit`
