# Milestone 4: Office Scene & Floating Window

> **Status: COMPLETE** — All 16 tasks done. 82 tests passing (20 new). Committed in `43fd2ec`.

**Goal**: Get the SpriteKit office scene rendering in a floating borderless window with placeholder sprites at desks, wired to `AgentMonitorService`. After this milestone, running the app shows an office with colored-square agents that move between states as real Claude Code sessions run.

**Human involvement needed at end**: Launch the app, start a Claude Code session, and visually confirm: an agent appears at a desk, its color changes as it reads/writes/thinks, and thought bubbles show current activity. This is the first "it works!" moment.

**Depends on**: Milestone 3 (working AgentMonitorService)

---

## Tasks

### 4.1 Configure floating borderless NSWindow
- **What**: Set up the app's main window as a floating, transparent, borderless window per VISION.md Section 7.
- **Behavior**:
  - `styleMask: .borderless`
  - `level: .floating` (stays above normal windows)
  - `isOpaque = false`, `backgroundColor = .clear`
  - `hasShadow = false`
  - `collectionBehavior = [.canJoinAllSpaces, .stationary]` (visible on all Spaces)
  - `isMovableByWindowBackground = true` (drag to reposition)
  - Fixed size: 512x384 points
- **Test (behavioral)**: Instantiate the window. Assert: `window.level == .floating`, `window.isOpaque == false`, `window.collectionBehavior` contains `.canJoinAllSpaces`, `window.styleMask` contains `.borderless`.

### 4.2 Embed SKView in the floating window
- **What**: Create an `SKView` that fills the window and hosts `OfficeScene`.
- **Behavior**:
  - SKView fills the window's content view
  - `showsFPS = false`, `showsNodeCount = false` (production settings)
  - `ignoresSiblingOrder = true` (optimization per VISION.md)
  - `preferredFramesPerSecond = 30`
  - Scene is presented with `.aspectFill` scaling
- **Test (behavioral)**: Create SKView with OfficeScene. Assert: scene is non-nil, scene size matches expected dimensions, `ignoresSiblingOrder` is true.

### 4.3 Render office background (walls and floor)
- **What**: Draw the office environment using colored rectangles (placeholder for pixel art tiles).
- **Behavior**:
  - Floor: warm tan (#C4B6A0) rectangle covering bottom 2/3 of scene
  - Walls: off-white (#EAE6DF) rectangle covering top 1/3
  - Subtle floor grain lines (#A89882) as thin rectangles
  - Background is static (no animation needed)
  - Uses warm dark shadows (#2D2D3D) — never pure black
- **Test (behavioral)**: Create OfficeScene. Assert: scene has child nodes named "floor" and "wall". Floor node's frame covers expected area.

### 4.4 Render desk layout (2 rows × 4 desks)
- **What**: Place 8 desks in the office using `OfficeLayout` positions.
- **Behavior**:
  - Two rows of 4 desks each
  - Each desk is a brown rectangle (#8B6544) with a darker accent (#6B4A30)
  - Each desk has a chair (circle, #5A6670) and monitor (small rectangle)
  - Monitor is off (dark) by default — turns on when agent is assigned
  - Desks are spaced evenly with room for sprites to sit
- **Test (behavioral)**: Create OfficeScene. Assert: 8 desk nodes exist. Each desk has child nodes for chair and monitor. Desk positions match `OfficeLayout.deskPosition(for:)`.

### 4.5 Implement AgentSprite rendering at desks
- **What**: When an agent appears in `AgentMonitorService.agents`, create an `AgentSprite` at the next available desk.
- **Behavior**:
  - Sprite is a colored rectangle (32x48) — orange-tinted for Claude Code, blue-tinted for Codex
  - Sprite is positioned at the desk's chair position
  - Name label below sprite shows agent name ("Agent 1")
  - Desk's monitor turns on (blue glow) when agent is assigned
  - New agents animate into position (fade in over 0.5s)
- **Test (behavioral)**: Add an agent to the service. Assert: OfficeScene has a child node of type AgentSprite. Sprite position is near the expected desk. Monitor node's color changed.

### 4.6 Implement agent removal from scene
- **What**: When an agent is removed from `AgentMonitorService.agents`, remove its sprite.
- **Behavior**:
  - Sprite fades out over 0.5s, then is removed from scene
  - Desk's monitor turns off
  - Desk becomes available for the next new agent
- **Test (behavioral)**: Add an agent, verify sprite exists. Remove the agent. Assert: sprite is removed (or has a fade-out action running). Desk is available.

### 4.7 Implement state-based sprite color changes
- **What**: AgentSprite changes color based on its agent's current state (placeholder for real animations).
- **Behavior**:
  - idle → Gray (#A0A0A0)
  - thinking → Yellow (#F0C040)
  - writingCode → Green (#50C878)
  - readingFiles → Cyan (#60B0D0)
  - runningCommand → Orange (#E89040)
  - searching → Lavender (#B080D0)
  - waitingForInput → Blue (#6090D0)
  - error → Red (#E05050)
  - finished → Dim gray (#707070)
- **Test (behavioral)**: Create an AgentSprite. Set state to each value. Assert: sprite's color matches expected hex for that state.

### 4.8 Implement status indicator dots
- **What**: Colored dot above each agent's desk showing current state.
- **Behavior**:
  - Small circle (8pt diameter) positioned above the desk
  - Color matches the state color table above
  - Error state uses a square shape instead of circle
  - Pulse animation on state change (scale 1.0 → 1.3 → 1.0 over 0.3s)
  - Steady glow during sustained activity
- **Test (behavioral)**: Create OfficeScene with one agent. Assert: status indicator node exists above the desk. Change state → assert color changes. Error state → assert shape is square-ish (width ≈ height).

### 4.9 Implement ThoughtBubble display
- **What**: Comic-book-style speech bubble above each agent showing current activity text.
- **Behavior**:
  - White rounded rectangle with black border
  - Small triangular tail pointing down to the agent
  - Text shows `taskDescription` from `AgentInfo` (e.g., "Reading src/auth/middleware.ts")
  - Updates on every state change
  - Maximum width: 200px — truncate long text with "..."
  - Fades to 50% opacity after 10 seconds of no change
- **Test (behavioral)**: Create an AgentSprite with taskDescription "Reading src/auth.ts". Assert: ThoughtBubble node exists. Its label text contains "Reading src/auth.ts". Change taskDescription → assert label updates.

### 4.10 Wire AgentMonitorService → OfficeScene updates
- **What**: Connect the service's `@Published agents` array to the SpriteKit scene so changes are reflected visually.
- **Behavior**:
  - When `agents` changes, diff against current scene sprites
  - New agents → create sprite (task 4.5)
  - Removed agents → remove sprite (task 4.6)
  - State changes → update sprite color, status dot, thought bubble
  - Use Combine or async observation to react to `@Published` changes
- **Test (behavioral)**: Create service and scene. Add agent to service. Assert: scene sprite count increases. Update agent state → assert sprite color changes. Remove agent → sprite count decreases.

### 4.11 Implement monitor glow effects on desks
- **What**: Each desk's monitor emits a subtle radial glow matching the agent's state.
- **Behavior**:
  - Writing code → green glow (#50C878 at 15% opacity)
  - Running command → amber glow (#E89040 at 10% opacity)
  - Idle → blue glow (#6090D0 at 8% opacity)
  - Error → red flicker (alternating #E05050 at 20% and 5% opacity, 0.5s cycle)
  - No agent → monitor dark, no glow
- **Test (behavioral)**: Create desk with agent in `.writingCode` state. Assert: a glow node exists near the monitor. Its color is greenish. Change to error → assert flicker action is running.

### 4.12 Implement LSUIElement (no dock icon)
- **What**: Configure the app as a background/accessory app with no dock icon.
- **Behavior**:
  - Set `LSUIElement = true` in Info.plist (or equivalent SwiftUI configuration)
  - App does not appear in the Dock
  - App does not appear in Cmd+Tab app switcher
  - Window is still visible and interactive
- **Test (behavioral)**: Check that `NSApplication.shared.activationPolicy()` is `.accessory` at launch.

### 4.13 Implement frame rate tiering
- **What**: Adjust SpriteKit frame rate based on app/window visibility.
- **Behavior**:
  - App is frontmost and window visible → 30 FPS
  - App is not frontmost but window visible → 10 FPS
  - Window is fully occluded (covered by other windows) → `isPaused = true` (0 FPS)
  - Uses `NSWindow.occlusionState` and `NSApplication.didResignActiveNotification`
- **Test (behavioral)**: Assert initial FPS is 30. Simulate app resign active notification → assert FPS is 10. Simulate occlusion state change → assert scene is paused.

### 4.14 Test empty office state
- **What**: Verify the scene looks correct with zero agents.
- **Test behavior**:
  - OfficeScene with no agents → all desks have powered-off monitors
  - No sprites, no thought bubbles, no status dots
  - Background (floor, walls) still renders
  - "The Bullpen" title is visible

### 4.15 Test full capacity (8 agents)
- **What**: Verify the scene handles maximum agents.
- **Test behavior**:
  - Add 8 agents to the service → 8 sprites at 8 desks
  - Each sprite at a unique desk position (no overlapping)
  - All 8 have status indicators and thought bubbles
  - Set each to a different state → verify visual independence

### 4.16 Verify office scene renders and all tests pass
- **What**: Run `swift build && swift test`. All tests from Milestones 1–4 pass.
- **Manual check**: Launch the app (`swift run`). Verify you see an empty office with 8 desks, wall, and floor.
- **Milestone gate**: The app is visually running. Placeholder sprites work. Ready for real art and menu bar.

---

## Parallelism

The following tasks can be done in parallel:
- **[4.1, 4.2]** (window setup) can be done together
- **[4.3, 4.4]** (background and desks) are independent
- **[4.5, 4.6, 4.7, 4.8, 4.9]** (sprite behaviors) depend on 4.3/4.4 but are independent of each other
- **4.10** depends on 4.5–4.9 (needs sprites to wire to)
- **[4.11, 4.12, 4.13]** are independent features
- **[4.14, 4.15]** are integration tests, depend on 4.10
- **4.16** depends on everything
