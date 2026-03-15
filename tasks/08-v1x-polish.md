# Milestone 8: V1.x Polish (Ambient Animations, Notifications, Office Cat)

**Goal**: Add the delightful polish that makes Bullpen feel alive — animated ambient elements (clock, plants, coffee steam, daylight), macOS notifications for key events, and the office cat NPC. After this milestone, Bullpen is ready for public release.

**Human involvement needed at end**: Final review of all polish elements. Approve notification wording. Watch the cat wander around the office. Ship it.

**Depends on**: Milestone 7 (feature-complete V1 MVP)

---

## Tasks

### 8.1 Implement wall clock with ticking second hand
- **What**: Animate the `decor_clock` decoration so its second hand ticks.
- **Behavior**:
  - Clock face is static (from texture)
  - Second hand is a thin SKShapeNode (1px wide line, red)
  - Rotates 6° per second (360° / 60s = full revolution per minute)
  - Uses `SKAction.rotate(byAngle:duration:)` repeating forever
  - Syncs roughly to system time (doesn't need to be exact)
- **Test (behavioral)**: Create clock node. Assert: it has a child node for the second hand. The second hand has a repeating rotate action.

### 8.2 Implement potted plant gentle sway
- **What**: Plants sway slightly as an ambient animation.
- **Behavior**:
  - 2-frame animation: lean left → lean right
  - 3-second cycle (per VISION.md)
  - Very subtle — max rotation ±2°
  - Uses `SKAction.sequence([rotateLeft, rotateRight])` repeating
- **Test (behavioral)**: Create plant node. Assert: it has a repeating rotation action. Rotation angle is small (< 5°).

### 8.3 Implement coffee mug steam particles
- **What**: Wispy steam particles rising from coffee mugs. (This may already be done in 6.15 — if so, verify and polish.)
- **Behavior**:
  - Tiny white particles at 30% opacity
  - Drift upward with slight randomized horizontal wobble
  - Birth rate: ~1/second, lifetime: 2 seconds
  - Speed: 5-10 pts/second upward
  - Particle scale: very small (2-3px)
- **Test (behavioral)**: Assert: coffee mug decoration has an SKEmitterNode child. Emitter birth rate > 0.

### 8.4 Implement window daylight simulation
- **What**: The office window decoration slowly shifts color to simulate passing time.
- **Behavior**:
  - Morning (6am–12pm): warm yellow tint
  - Afternoon (12pm–6pm): bright white/neutral
  - Evening (6pm–9pm): warm orange/sunset
  - Night (9pm–6am): dark blue
  - Transitions smoothly over minutes (not abrupt)
  - Uses system time to determine current period
  - Color applied as `colorBlendFactor` on the window texture
- **Test (behavioral)**: Set system time context to evening. Assert: window node's color blend has an orange/warm component. Set to night → assert blue component.

### 8.5 Implement empty desk ambient state
- **What**: Unoccupied desks should look powered-off but still part of the scene.
- **Behavior**:
  - Monitor uses `furniture_monitor_off` texture
  - No glow effect
  - Chair pushed slightly back from desk (subtle offset)
  - Optional: screen saver pattern (tiny bouncing dot) on one random empty desk
- **Test (behavioral)**: Create scene with 3 agents on 8 desks. Assert: 5 empty desks have off-monitor textures. No glow nodes on empty desks.

### 8.6 Implement macOS notification: agent finished
- **What**: Send a macOS notification when an agent completes its task.
- **Behavior**:
  - Title: "Agent finished"
  - Body: "Agent 1 completed in <working directory basename>"
  - Category: informational (no actions needed)
  - Uses `UNUserNotificationCenter`
  - Request notification permission on first agent finish event
  - Only fires if the app window is not visible (don't spam when user is watching)
  - Debounce: max 1 notification per agent per 60 seconds
- **Test (behavioral)**: Transition agent to `.finished` with window hidden. Assert: a notification request was added to `UNUserNotificationCenter`. With window visible → no notification.

### 8.7 Implement macOS notification: agent error
- **What**: Send a macOS notification when an agent encounters an error.
- **Behavior**:
  - Title: "Agent error"
  - Body: "Agent 1 hit an error: <error summary truncated to 80 chars>"
  - Category: attention-needed (could have action buttons later)
  - Sound: default system notification sound
  - Only fires if window is not visible
  - Debounce: max 1 error notification per agent per 30 seconds (errors can be noisy)
- **Test (behavioral)**: Transition agent to `.error` with window hidden. Assert: notification request exists with title "Agent error".

### 8.8 Implement notification permission request
- **What**: Request notification permissions the first time a notification would be sent.
- **Behavior**:
  - Check `UNUserNotificationCenter.current().getNotificationSettings()`
  - If `.notDetermined`, request authorization for `.alert`, `.sound`
  - If `.denied`, silently skip notifications (don't nag)
  - Store permission state to avoid repeated checks
- **Test (behavioral)**: Assert: notification center's `requestAuthorization` is called on first notification attempt.

### 8.9 Generate office cat sprite assets (if not done in Milestone 5)
- **What**: Ensure all 4 cat sprites exist in `Assets/sprites/cat/`.
- **Verify**: `cat_idle.png`, `cat_walk_1.png`, `cat_walk_2.png`, `cat_sleep.png` all exist and are valid PNGs.

### 8.10 Implement office cat NPC node
- **What**: Create a `CatSprite` (SKSpriteNode) for the office cat.
- **Behavior**:
  - 32x32 sprite using cat textures
  - Exists in the scene at all times (even with 0 agents)
  - Initial position: sleeping near a random desk
  - Has its own animation states: idle (sitting), walking, sleeping
  - Does not have a thought bubble or status indicator
- **Test (behavioral)**: Create OfficeScene with CatSprite. Assert: cat node exists in scene. Cat has a non-nil texture.

### 8.11 Implement cat wandering behavior
- **What**: The cat periodically wanders between desks, visiting active agents.
- **Behavior**:
  - Every 30–120 seconds (random interval), cat picks a destination
  - Destination: random desk (prefers desks with active agents, 70% chance)
  - Cat walks to destination using `SKAction.move(to:duration:)` at ~20pts/second
  - Walking uses 2-frame walk animation (cat_walk_1, cat_walk_2)
  - Facing direction flips based on movement direction
  - On arrival: sits idle for 10-30 seconds, then picks new destination
- **Test (behavioral)**: Start cat wandering. Assert: cat has a move action. After some time, cat's position has changed. Cat sprite is flipped based on direction.

### 8.12 Implement cat sleeping behavior
- **What**: If no agents are active, the cat falls asleep.
- **Behavior**:
  - If all agents are `.idle` or `.finished` (or no agents), cat goes to sleep after 60 seconds
  - Uses `cat_sleep` texture
  - ZZZ particles above the cat (same style as idle agent ZZZ from 6.16)
  - Wakes up when any agent becomes active (transitions to idle → walk)
- **Test (behavioral)**: Set all agents to idle. Wait for sleep timeout. Assert: cat texture is `cat_sleep`. ZZZ particles exist. Activate an agent → cat wakes up.

### 8.13 Implement cat interaction with agents
- **What**: When the cat arrives at an active agent's desk, small visual interaction.
- **Behavior**:
  - Cat sits near the agent's chair
  - Agent sprite plays a brief "pet cat" micro-animation (hand reach down, 2 frames) — or skip if too complex, just have the cat sit there
  - Cat purrs (tiny heart particle above cat, appears for 2 seconds)
  - After 10-20 seconds, cat moves on
- **Test (behavioral)**: Move cat to an active agent's desk. Assert: heart particle appears near cat after arrival.

### 8.14 Implement thought bubble horizontal scroll for long text
- **What**: Long file paths in thought bubbles should scroll horizontally.
- **Behavior**:
  - If text exceeds the 200px max width, enable horizontal scroll animation
  - Text scrolls left at ~30px/second, pauses 2s at start and end, then loops
  - Short text (fits in bubble) does not scroll
- **Test (behavioral)**: Create ThoughtBubble with a very long path ("Reading /very/long/path/to/some/deeply/nested/file.ts"). Assert: label has a repeating move action. Short text → no move action.

### 8.15 Implement thought bubble fade after inactivity
- **What**: Thought bubble fades if no new activity for 10 seconds.
- **Behavior**:
  - After 10 seconds with no `taskDescription` update, fade to 50% opacity
  - New activity → immediately restore to 100% opacity
  - Fade is animated (1 second ease-out)
- **Test (behavioral)**: Create ThoughtBubble. Wait 10+ seconds with no update. Assert: bubble alpha is ~0.5. Update task description → assert alpha returns to 1.0.

### 8.16 Implement status indicator pulse on state change
- **What**: Status dot pulses when the agent's state changes.
- **Behavior**:
  - On state change: scale up to 1.3x → back to 1.0x over 0.3 seconds
  - Uses `SKAction.sequence([scaleUp, scaleDown])`
  - Only pulses on change, not continuously
- **Test (behavioral)**: Change agent state. Assert: status indicator has a scale action with target scale 1.3.

### 8.17 Final integration test: full app experience
- **What**: Run `swift build && swift test`. All tests pass from Milestones 1–8.
- **Manual QA**:
  - [ ] Office renders with pixel art (not colored squares)
  - [ ] Agents animate through all 9 states
  - [ ] Cat wanders between desks
  - [ ] Cat sleeps when no agents active
  - [ ] Clock ticks
  - [ ] Plants sway
  - [ ] Coffee steam rises
  - [ ] Window daylight shifts
  - [ ] Notifications fire on finish/error (when window hidden)
  - [ ] Thought bubbles scroll long text
  - [ ] Thought bubbles fade after inactivity
  - [ ] Status dots pulse on change
  - [ ] Menu bar badge accurate
  - [ ] Detail popover shows all info
  - [ ] Window draggable, visible on all Spaces
  - [ ] CPU < 5% with 8 agents active
  - [ ] Memory < 50 MB
- **Milestone gate**: V1 + V1.x is complete. Ready for distribution.

---

## Parallelism

Three independent tracks can be done simultaneously:

**Track A: Ambient animations** (8.1–8.5) — all independent of each other
**Track B: Notifications** (8.6–8.8) — sequential within track
**Track C: Office cat** (8.9–8.13) — sequential within track

After tracks complete:
- **[8.14, 8.15, 8.16]** are independent polish items
- **8.17** depends on everything
