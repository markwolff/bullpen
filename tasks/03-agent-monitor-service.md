# Milestone 3: Agent Monitor Service & State Machine

> **Status: COMPLETE** — All 12 tasks done. 62 tests passing (14 new). Committed in `4f485ba`.

**Goal**: Wire log readers and LogWatcher into `AgentMonitorService` so it discovers sessions, tracks agent state transitions in real time, and manages agent lifecycle (appear, update, disappear). After this milestone, the service layer is fully functional — feed it log files and it produces a live `[AgentInfo]` array.

**Human involvement needed at end**: Run the app and start a Claude Code session in a terminal. Verify that `AgentMonitorService.agents` updates (check via debug print or breakpoint). This confirms the full pipeline: file system → log reader → state machine → published state.

**Depends on**: Milestone 2 (working log readers)

---

## Tasks

### 3.1 Implement AgentMonitorService.startMonitoring()
- **What**: Initialize LogWatcher instances for Claude Code and Codex log directories. Start watching for new files and file modifications.
- **Behavior**:
  - Creates a `LogWatcher` for `~/.claude/projects/` (recursive, watches for .jsonl files)
  - Creates a `LogWatcher` for `~/.codex/history/` (watches for .json files)
  - Calls `discoverSessions()` on both readers immediately to find already-running sessions
  - Sets up a periodic timer (every 5 seconds) to re-discover sessions (catches sessions started between FSEvents)
  - Handles missing directories gracefully (directory doesn't exist → skip, don't crash)
- **Test**: Create temp directories with fixture files. Call `startMonitoring()` with custom paths. Verify `agents` array populates with correct count.

### 3.2 Implement session-to-agent creation
- **What**: When a new session is discovered, create an `AgentInfo` and add it to the `agents` array.
- **Behavior**:
  - New session file detected → create `AgentInfo` with state `.idle`, agent type based on reader (`.claudeCode` or `.codex`)
  - Assign the session's working directory (from log metadata) if available
  - Auto-generate agent name: "Agent 1", "Agent 2", etc. (incrementing)
  - Add to `agents` array (published, triggers UI update)
  - Duplicate detection: if session ID already exists in agents, skip
- **Test**: Start monitoring with a temp dir containing 2 Claude Code fixtures and 1 Codex fixture. Verify 3 agents appear in `agents` array with correct types and sequential names.

### 3.3 Implement file modification → state update pipeline
- **What**: When LogWatcher detects a file modification, read new activities and update the corresponding agent's state.
- **Behavior**:
  - LogWatcher fires callback on `.jsonl` file modification
  - Service looks up which agent owns this session file
  - Calls `readActivities(from: lastOffset)` on the appropriate log reader
  - For each new activity: update agent's `state` and `taskDescription` (from activity summary)
  - Store new offset for next read
- **Test**: Create a temp `.jsonl` file with 2 lines. Start monitoring. Append 1 more line with a Write tool_use. Verify the agent's state transitions to `.writingCode` and `taskDescription` updates.

### 3.4 Implement state machine transitions
- **What**: Ensure state transitions follow the state machine defined in VISION.md Section 8.
- **Behavior**:
  - Tool use events → state based on tool type (per mapping in 2.3)
  - Text-only assistant responses → `.thinking`
  - Tool result with error → `.error`
  - `stop_reason: "end_turn"` → `.finished`
  - Any state can transition to any other state via a new event (the state machine is not restrictive about transitions — it's event-driven)
- **Test**: Create a fixture that exercises these transitions: idle → thinking → readingFiles → writingCode → runningCommand → error → thinking → finished. Feed it through the monitor service. Verify agent state at each step.

### 3.5 Implement idle timeout detection
- **What**: If no new log activity is detected for 30 seconds, transition agent to `.idle`.
- **Behavior**:
  - Track `lastActivityTime` per agent
  - Timer checks every 5 seconds: if `now - lastActivityTime > 30s`, set state to `.idle`
  - If agent is already `.finished`, don't transition to `.idle` (finished is terminal until new activity)
  - New activity resets the timer
- **Test**: Create an agent via fixture, set its state to `.writingCode`. Advance time (or use a short timeout for testing, e.g., 0.5s). Verify state transitions to `.idle`. Then simulate new activity — verify it leaves `.idle`.

### 3.6 Implement agent removal on session end
- **What**: Remove agents whose sessions have ended (no new writes for extended period).
- **Behavior**:
  - If agent has been `.idle` for 5 minutes AND no new file modifications detected → mark as stale
  - If agent is `.finished` for 2 minutes → remove from `agents` array
  - Removal triggers UI update (sprite disappears from office)
  - Don't remove agents that are actively erroring (they need attention)
- **Test**: Create an agent, set to `.finished`. Wait for removal timeout. Verify agent is removed from `agents` array.

### 3.7 Implement concurrent agent tracking (up to 8)
- **What**: Verify the service correctly tracks multiple simultaneous agents.
- **Behavior**:
  - Support up to 8 agents simultaneously (as per VISION.md)
  - If a 9th session is detected, either queue it or log a warning (don't crash)
  - Each agent has independent state — one agent's error doesn't affect others
  - State updates are atomic per-agent (no race conditions)
- **Test**: Create 8 temp session files. Start monitoring. Verify all 8 agents appear. Simulate different states on each. Verify independence (change one agent's state, others unchanged).

### 3.8 Implement AgentMonitorService.stopMonitoring()
- **What**: Clean shutdown of all watchers and timers.
- **Behavior**:
  - Stop all LogWatcher instances
  - Cancel all timers (discovery timer, idle timeout timer)
  - Clear agents array
  - Idempotent — calling stop when not monitoring is a no-op
- **Test**: Start monitoring, verify agents appear. Stop monitoring, verify watchers are stopped and agents array is cleared. Start again — verify it works (restart cycle).

### 3.9 Test thread safety of agent state updates
- **What**: Verify that concurrent state updates don't cause data races.
- **Behavior**:
  - `agents` array is `@Published` on `@MainActor` — all mutations must happen on the main actor
  - LogWatcher callbacks come from background threads — service must dispatch to main actor
  - Multiple file modifications arriving simultaneously must serialize correctly
- **Test**: Simulate rapid concurrent modifications to multiple session files from background threads. Verify no crashes and final state is consistent.

### 3.10 Test the full discovery-to-state pipeline with fixtures
- **What**: End-to-end integration test using fixture files.
- **Behavior**:
  - Set up temp directory structure mimicking `~/.claude/projects/` with fixture files
  - Start `AgentMonitorService` pointing at temp directory
  - Verify: agents discovered, states correct, summaries populated
  - Append new data to a fixture file → verify state updates
  - Verify token usage is tracked (from fixture's `usage` fields)
- **This is the key integration test** — if this passes, the service layer works.

### 3.11 Test AgentMonitorService with empty/missing directories
- **What**: Verify graceful handling of edge cases.
- **Test behavior**:
  - No `~/.claude/` directory → no crash, 0 agents
  - Empty `~/.claude/projects/` → 0 agents
  - Directory with non-log files → 0 agents
  - Permission denied on directory → skip gracefully, 0 agents
  - Directory appears after monitoring starts → agents discovered on next scan

### 3.12 Verify full service layer compiles and passes
- **What**: Run `swift build && swift test`. All Milestone 1, 2, and 3 tests pass.
- **Milestone gate**: The service layer is complete. An agent writing to `~/.claude/projects/` will now be tracked in `AgentMonitorService.agents`.

---

## Parallelism

The following tasks can be done in parallel:
- **[3.1, 3.2, 3.3, 3.4]** form the core pipeline and should be done sequentially
- **[3.5, 3.6]** (timeout and removal) are independent of each other but depend on 3.1–3.4
- **[3.7, 3.8, 3.9]** (concurrent tracking, shutdown, thread safety) are independent and can parallelize
- **[3.10, 3.11]** are integration tests that depend on everything above
- **3.12** depends on everything
