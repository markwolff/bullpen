# Milestone 6: Sprite Integration & Animations

> **Status: COMPLETE** — All 18 tasks done. 112 tests passing (30 new). Committed in `09fe274`. Uses programmatic placeholder textures until real PNGs from Milestone 5 are generated.

**Goal**: Replace placeholder colored rectangles with real pixel art sprites, build texture atlases, and implement all 9 animation states with smooth transitions and particle effects. After this milestone, the office scene looks polished with animated characters.

**Human involvement needed at end**: Watch the app running with a live Claude Code session. Confirm animations look good, transitions are smooth, and the overall feel is "charming" per the VISION.md design principles.

**Depends on**: Milestone 4 (working office scene with placeholders) AND Milestone 5 (generated pixel art assets)

---

## Tasks

### 6.1 Build SpriteKit texture atlases from generated PNGs
- **What**: Create `.atlas` directories (or configure in Xcode asset catalog) that batch sprite PNGs into texture atlases for efficient rendering.
- **Behavior**:
  - Group character sprites by agent type: `claude.atlas`, `codex.atlas`
  - Group furniture into `furniture.atlas`
  - Group decorations into `decorations.atlas`
  - Group tiles into `tiles.atlas`
  - Group cat into `cat.atlas`
  - Use `.nearest` texture filtering (preserves crisp pixel edges on Retina)
- **Test (behavioral)**: Load texture atlas by name. Assert: atlas contains expected texture names. Textures have non-zero size.

### 6.2 Replace placeholder sprites with pixel art textures
- **What**: Update `AgentSprite` to use texture-based `SKSpriteNode` instead of colored rectangles.
- **Behavior**:
  - On creation, load the appropriate texture for the agent type (Claude → orange character, Codex → blue character)
  - Initial texture is the idle state
  - Sprite size remains 32x48 (scaled up with `.nearest` filtering for Retina)
  - `texture.filteringMode = .nearest` on all textures
- **Test (behavioral)**: Create an AgentSprite for a Claude agent. Assert: sprite has a non-nil texture. Texture filtering mode is `.nearest`. Sprite size is 32x48.

### 6.3 Replace placeholder desks with pixel art furniture
- **What**: Update desk rendering in `OfficeScene` to use furniture textures.
- **Behavior**:
  - Desks use `furniture_desk` texture
  - Chairs use `furniture_chair` texture
  - Monitors use `furniture_monitor_off` by default, switch to appropriate glow texture when agent is assigned
  - All furniture uses `.nearest` filtering
- **Test (behavioral)**: Create OfficeScene. Assert: desk nodes have non-nil textures. Monitor changes texture when agent state changes.

### 6.4 Replace placeholder background with tile textures
- **What**: Tile the floor and walls using generated tile textures.
- **Behavior**:
  - Floor covered with repeating `tile_floor_wood` tiles
  - Walls covered with repeating `tile_wall` tiles
  - Tiles seamlessly connect (no visible seams)
- **Test (behavioral)**: Create OfficeScene. Assert: floor area contains tile nodes. Tile textures are non-nil.

### 6.5 Implement idle animation (4 frames, 0.5 FPS)
- **What**: Idle state shows a gentle bob with occasional blink.
- **Behavior**:
  - 4-frame loop: neutral → slight bob down → neutral → blink
  - Cycle time: 8 seconds (0.5 FPS)
  - Subtle and calm — this is the default resting state
  - Uses `SKAction.animate(with:)` looping forever
- **Test (behavioral)**: Set agent to `.idle`. Assert: sprite has a repeating animation action. Action has 4 textures.

### 6.6 Implement thinking animation (4 frames, 0.5 FPS)
- **What**: Thinking state shows the character leaning back with hand on chin.
- **Behavior**:
  - 4-frame loop: lean back → hand to chin → look up → look down
  - Cycle time: 8 seconds
  - Particle effect: tiny sparkles drifting upward from head (SKEmitterNode)
- **Test (behavioral)**: Set agent to `.thinking`. Assert: sprite has animation action. A particle emitter node exists as child of the sprite.

### 6.7 Implement writingCode animation (2 frames, 8 FPS)
- **What**: Writing state shows rapid typing.
- **Behavior**:
  - 2-frame loop: hands left → hands right (rapid keyboard movement)
  - Very fast cycle: 0.125s per frame (8 FPS)
  - This is the "productive" state — most energetic animation
- **Test (behavioral)**: Set agent to `.writingCode`. Assert: sprite has animation action with 2 textures. Time per frame ≈ 0.125s.

### 6.8 Implement readingFiles animation (3 frames, 0.3 FPS)
- **What**: Reading state shows the character leaning forward studying the screen.
- **Behavior**:
  - 3-frame loop: lean forward → head tilt left → head tilt right
  - Slow cycle: ~10 seconds (0.3 FPS)
  - Calm, focused — less energetic than writing
- **Test (behavioral)**: Set agent to `.readingFiles`. Assert: sprite has animation action with 3 textures.

### 6.9 Implement runningCommand animation (2 frames, 1 FPS)
- **What**: Running command shows the character watching the screen intently.
- **Behavior**:
  - 2-frame loop: still watching → slight lean in
  - 1 second cycle
  - Monitor glow should be amber (#E89040)
- **Test (behavioral)**: Set agent to `.runningCommand`. Assert: sprite has animation action. Monitor glow is amber.

### 6.10 Implement searching animation (4 frames, 1 FPS)
- **What**: Searching shows the character looking left and right.
- **Behavior**:
  - 4-frame loop: look left → center → look right → center
  - 4 second cycle (1 FPS)
- **Test (behavioral)**: Set agent to `.searching`. Assert: sprite has animation action with 4 textures.

### 6.11 Implement waitingForInput animation (4 frames, 2 FPS)
- **What**: Waiting shows impatient fidgeting.
- **Behavior**:
  - 4-frame loop: drum fingers → tap foot → drum fingers → sigh
  - 2 second cycle (2 FPS)
- **Test (behavioral)**: Set agent to `.waitingForInput`. Assert: sprite has animation action with 4 textures.

### 6.12 Implement error animation (2 frames, 2 FPS)
- **What**: Error shows a facepalm/recoil.
- **Behavior**:
  - 2-frame loop: recoil → hands on head
  - Fast cycle: 0.5s per frame
  - Particle effect: red sparks near desk (SKEmitterNode)
  - **Transition into error is instant** (no blend — jarring is intentional per VISION.md)
- **Test (behavioral)**: Set agent to `.error`. Assert: sprite has animation action. Particle emitter exists. Transition was instant (no blend action).

### 6.13 Implement finished animation (4 frames, 1 FPS)
- **What**: Finished shows the character standing and stretching.
- **Behavior**:
  - 4-frame sequence (plays once, not loop): stand up → stretch → step back → idle at standing position
  - 4 second total
  - Particle effect: brief confetti burst (SKEmitterNode, auto-removes after 2s)
- **Test (behavioral)**: Set agent to `.finished`. Assert: sprite has an animation action. Confetti emitter exists temporarily.

### 6.14 Implement state transition blending
- **What**: Smooth transitions between animation states (except error).
- **Behavior**:
  - When state changes, cross-fade between old and new animation over 0.3s
  - Use `SKAction.fadeOut` on old sprite → swap texture → `SKAction.fadeIn` (or alpha blending)
  - Error transitions bypass blending (instant snap)
  - Finished → idle should use a gentle transition
- **Test (behavioral)**: Change state from `.idle` to `.writingCode`. Assert: a fade/blend action is running with duration ~0.3s. Change to `.error` → assert no blend action (instant).

### 6.15 Implement coffee mug steam particles (ambient)
- **What**: Small white wisps rising from coffee mugs on desks — always on regardless of agent state.
- **Behavior**:
  - Tiny white particles (#FFFFFF at 30% opacity) drifting upward
  - Birth rate: 1 particle/second, lifetime: 2 seconds
  - Very subtle — should not distract
- **Test (behavioral)**: Assert: each desk with a coffee mug decoration has an emitter node as child.

### 6.16 Implement idle ZZZ particles
- **What**: When an agent has been idle for > 60 seconds, show floating "Z" letters above their head.
- **Behavior**:
  - SKLabelNode "Z" drifting upward and fading
  - New Z appears every 2 seconds
  - Removed immediately when state changes from idle
- **Test (behavioral)**: Set agent to `.idle`. Simulate 60+ seconds. Assert: ZZZ emitter/action exists. Change state → assert ZZZ removed.

### 6.17 Place decorations in the office scene
- **What**: Add plants, coffee mugs, lamp, window, whiteboard, clock to the scene.
- **Behavior**:
  - Plants at corners of the office (using decoration textures)
  - Coffee mug on each occupied desk
  - Lamp on alternating desks
  - Window on the back wall
  - Whiteboard on the side wall
  - Clock on the wall (static for now — animated in Milestone 8)
- **Test (behavioral)**: Create OfficeScene. Assert: decoration nodes exist at expected positions. Each decoration has a non-nil texture.

### 6.18 Verify all animations and sprites work together
- **What**: Run `swift build && swift test`. All tests pass. Launch app and visually inspect.
- **Manual check**: With a live Claude Code session, verify:
  - Agent appears with correct pixel art sprite
  - State transitions trigger correct animations
  - Transitions blend smoothly (except error)
  - Particle effects appear (thinking sparkles, error sparks, confetti)
  - Coffee steam is visible on mugs
  - Decorations are placed naturally
- **Milestone gate**: The office scene is visually complete with real art and animations.

---

## Parallelism

The following tasks can be done in parallel:
- **[6.1]** must be done first (atlas needed by everything else)
- **[6.2, 6.3, 6.4]** (replace placeholders) are independent after 6.1
- **[6.5–6.13]** (9 animation states) are all independent of each other, depend on 6.2
- **[6.14]** depends on at least 2 animation states being done
- **[6.15, 6.16, 6.17]** (particles and decorations) are independent, depend on 6.1
- **6.18** depends on everything
