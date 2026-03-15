# Milestone 7: UI & Interaction (Menu Bar, Detail Popover, Window Management)

**Goal**: Add the menu bar presence (NSStatusItem), detail popover on agent click, and final window management behaviors. After this milestone, the app is feature-complete for V1 MVP — a user can see agents in the office, click them for details, and manage the window from the menu bar.

**Human involvement needed at end**: Full manual QA pass — launch, use menu bar controls, click agents, drag window, verify on multiple Spaces. This is the V1 MVP acceptance test.

**Depends on**: Milestone 4 (floating window), Milestone 6 (sprites and animations)

---

## Tasks

### 7.1 Create NSStatusItem (menu bar icon)
- **What**: Add a persistent icon in the macOS menu bar.
- **Behavior**:
  - Small icon: pixel-art office building or a tiny character sprite (16x16)
  - Always visible when app is running
  - Uses `NSStatusBar.system.statusItem(withLength: .variable)`
- **Test (behavioral)**: After app setup, assert: `NSStatusBar.system` has a status item with a non-nil image.

### 7.2 Implement agent count badge on menu bar icon
- **What**: Show the number of active agents as a badge on the status item.
- **Behavior**:
  - Badge text: number of agents where state is NOT `.idle` and NOT `.finished`
  - "0" → no badge (just the icon)
  - "1"–"8" → number badge
  - Updates reactively when `AgentMonitorService.agents` changes
  - Badge is a small attributed string or overlaid on the icon image
- **Test (behavioral)**: Set 3 agents to active states. Assert: status item title/badge shows "3". Set all to idle → badge disappears.

### 7.3 Implement click-to-toggle window visibility
- **What**: Clicking the menu bar icon toggles the floating window visibility.
- **Behavior**:
  - Window visible → click → `window.orderOut(nil)` (hide)
  - Window hidden → click → `window.makeKeyAndOrderFront(nil)` (show)
  - Remember last window position between toggles
- **Test (behavioral)**: Assert: window is visible. Simulate click action → assert window is not visible. Simulate again → visible.

### 7.4 Implement right-click context menu
- **What**: Right-clicking the menu bar icon shows a dropdown menu.
- **Menu items**:
  - "Show Office" / "Hide Office" (toggles window, label reflects current state)
  - Separator
  - "Preferences..." (placeholder for now — opens a simple sheet)
  - Separator
  - "Quit Bullpen" (`NSApplication.shared.terminate(nil)`)
- **Test (behavioral)**: Assert: status item has a menu. Menu has items titled "Show Office", "Preferences...", "Quit Bullpen".

### 7.5 Implement agent click detection in SpriteKit scene
- **What**: Detect clicks/taps on agent sprites in the office scene.
- **Behavior**:
  - Override `mouseDown(with:)` in OfficeScene
  - Hit-test against agent sprite nodes
  - If an agent sprite is hit, emit the agent's ID to the UI layer
  - If background is hit, dismiss any open popover
- **Test (behavioral)**: Simulate a mouse event at an agent sprite's position. Assert: the scene reports the correct agent ID. Simulate click on empty space → no agent ID reported.

### 7.6 Implement detail popover (SwiftUI)
- **What**: Show a SwiftUI popover when an agent sprite is clicked, displaying detailed session info.
- **Content**:
  - **Agent name**: "Agent 1" (or session-derived name)
  - **Agent type**: "Claude Code" or "Codex CLI" with colored badge
  - **Current state**: Display label + colored dot + duration in state (e.g., "Writing Code · 2m 30s")
  - **Current file/tool**: The task description (e.g., "Editing src/auth/middleware.ts")
  - **Session duration**: "Started 14 minutes ago"
  - **Token usage**: "Input: 12,345 · Output: 678" (from log `usage` fields)
  - **Last 5 tool calls**: Mini timeline showing tool name + file, most recent first
  - **Working directory**: Full path to the project (from log metadata)
- **Behavior**:
  - Appears as a popover anchored near the clicked sprite
  - Dismisses when clicking elsewhere or clicking the same sprite again
  - Updates in real time as the agent's state changes
  - Styled with system fonts and subtle background blur
- **Test (behavioral)**: Create popover with mock AgentInfo. Assert: all labels render non-empty text. Agent type badge has correct color.

### 7.7 Implement token usage tracking in AgentInfo
- **What**: Accumulate token usage from log entries into `AgentInfo`.
- **Behavior**:
  - `AgentInfo` gets new fields: `totalInputTokens: Int`, `totalOutputTokens: Int`
  - Each parsed activity with token data adds to the running total
  - Token counts update as new log lines are read
- **Test (behavioral)**: Create an agent, feed it activities with known token counts. Assert: `totalInputTokens` and `totalOutputTokens` match the sum.

### 7.8 Implement last-5-tool-calls tracking in AgentInfo
- **What**: Maintain a rolling buffer of the 5 most recent tool calls for the detail popover.
- **Behavior**:
  - `AgentInfo` gets a new field: `recentTools: [AgentActivity]` (max 5, FIFO)
  - New activities push onto the front, oldest drops off when > 5
  - Only tool_use activities count (not text/thinking)
- **Test (behavioral)**: Feed 7 tool activities to an agent. Assert: `recentTools` has exactly 5 items. The oldest 2 are gone. Order is most-recent-first.

### 7.9 Implement session duration tracking
- **What**: Track when each agent session started and compute duration.
- **Behavior**:
  - `AgentInfo` gets `sessionStartTime: Date`
  - Set on first activity from the session
  - Duration computed as `Date.now - sessionStartTime`
  - Display in popover as "Started X minutes ago" or "X hours ago"
- **Test (behavioral)**: Create agent with sessionStartTime 10 minutes ago. Assert: duration string contains "10" and "minutes".

### 7.10 Implement state duration tracking
- **What**: Track how long an agent has been in its current state.
- **Behavior**:
  - `AgentInfo` gets `stateEnteredAt: Date`
  - Updated every time `state` changes
  - Duration displayed as "2m 30s" in the detail popover
- **Test (behavioral)**: Set agent state to `.writingCode`. Wait 2 seconds. Assert: state duration is ~2 seconds.

### 7.11 Implement working directory extraction from logs
- **What**: Extract the project working directory from log file path.
- **Behavior**:
  - Claude Code: working directory is encoded in the project hash path (`~/.claude/projects/<hash>/`)
  - Alternatively, parse from Bash tool `cwd` arguments or file paths
  - Codex: directly from `cwd` field in session JSON
  - Store in `AgentInfo.workingDirectory: String?`
- **Test (behavioral)**: Parse Codex fixture (which has `cwd` field). Assert: `workingDirectory` is non-nil and contains a path.

### 7.12 Implement window dragging and position persistence
- **What**: Users can drag the floating window to reposition it. Position persists across app restarts.
- **Behavior**:
  - `isMovableByWindowBackground = true` (already set in Milestone 4, verify it works with real content)
  - On window move, save position to `UserDefaults` (key: "windowPosition")
  - On app launch, restore saved position (or default to bottom-right of screen)
- **Test (behavioral)**: Set window position to (100, 200). Save. Restore. Assert: position matches.

### 7.13 Test popover content updates in real time
- **What**: Verify the detail popover updates when the underlying agent changes.
- **Test behavior**:
  - Open popover for Agent 1
  - Change Agent 1's state from `.reading` to `.writingCode`
  - Assert: popover's state label updates to "Writing Code"
  - Assert: state duration resets

### 7.14 Test menu bar badge accuracy
- **What**: Verify badge count is accurate under various conditions.
- **Test behavior**:
  - 0 active agents → no badge
  - 3 agents: 1 writing, 1 reading, 1 idle → badge shows "2" (idle doesn't count)
  - Agent finishes → badge decrements
  - Agent errors → still counts as active (badge includes it)
  - All agents idle or finished → no badge

### 7.15 Verify all UI interactions work and tests pass
- **What**: Run `swift build && swift test`. All tests pass.
- **Manual QA checklist**:
  - [ ] Menu bar icon visible
  - [ ] Click toggles window
  - [ ] Right-click shows menu
  - [ ] Agent count badge correct
  - [ ] Click agent shows popover
  - [ ] Popover shows all data fields
  - [ ] Click elsewhere dismisses popover
  - [ ] Window draggable
  - [ ] Window visible on all Spaces
  - [ ] Quit from menu works
- **Milestone gate**: V1 MVP is feature-complete. All core features from VISION.md Section 6 are implemented.

---

## Parallelism

The following tasks can be done in parallel:
- **[7.1, 7.2, 7.3, 7.4]** (menu bar) are sequential (each builds on previous)
- **[7.5, 7.6]** (click detection + popover) are sequential
- **[7.7, 7.8, 7.9, 7.10, 7.11]** (AgentInfo extensions) are all independent of each other
- **Menu bar work** and **popover work** and **AgentInfo extensions** are three independent tracks
- **[7.12]** is independent of everything
- **[7.13, 7.14]** are integration tests, depend on their respective features
- **7.15** depends on everything
