# Milestone 1: Foundation & Test Infrastructure

> **Status: COMPLETE** — All 13 tasks done. 17 tests passing. Committed in `a347e8b`.

**Goal**: Fix the broken test target, establish test fixtures and helpers, validate all existing models, and scaffold the asset generation tool. After this milestone, `swift test` passes and the project has a solid foundation for TDD on all subsequent work.

**Human involvement needed at end**: Confirm `swift test` passes on their machine. Provide `AI_GATEWAY_API_KEY` for Milestone 5.

---

## Tasks

### 1.1 Migrate test target from XCTest to Swift Testing
- **What**: Replace `import XCTest` and `XCTestCase` in `AgentStateTests.swift` with Swift Testing (`import Testing`, `@Test`, `#expect`).
- **Update `Package.swift`**: Ensure the test target uses `.testing` dependency if needed, or just rely on Swift 6's built-in Testing framework.
- **Verify**: `swift test` compiles and all existing tests pass.
- **Test behavior**: Each `@Test` should test a user-visible behavior, not implementation details.

### 1.2 Create Claude Code log fixture files
- **What**: Create `Tests/Fixtures/ClaudeCode/` with realistic `.jsonl` fixture files.
- **Files to create**:
  - `simple-session.jsonl` — A short session: user message → assistant thinks → reads a file → writes a file → end_turn. ~5 JSONL lines.
  - `multi-tool-session.jsonl` — Session with all tool types: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch. Exercises every state transition.
  - `error-session.jsonl` — Session where a tool_result contains an error (e.g., Bash exits non-zero). Tests error state detection.
  - `long-session.jsonl` — 50+ JSONL lines simulating a realistic refactoring session with interleaved thinking/reading/writing. Tests incremental reading.
- **Format**: Must match the schema in VISION.md Appendix A exactly. Include realistic `usage` fields, timestamps, `sessionId`, `model`, `stop_reason`.
- **Verify**: Files are valid JSONL (each line is valid JSON).

### 1.3 Create Codex CLI log fixture files
- **What**: Create `Tests/Fixtures/Codex/` with realistic `.json` fixture files.
- **Files to create**:
  - `simple-session.json` — Short session: user prompt → file_read → shell → response.
  - `multi-tool-session.json` — Session using file_read, file_write, file_edit, shell.
  - `error-session.json` — Session where a shell command fails.
- **Format**: Must match the schema in VISION.md Appendix B exactly. Include `sessionId`, `startTime`, `endTime`, `model`, `provider`, `approvalMode`, `cwd`, `items` array.
- **Verify**: Files are valid JSON.

### 1.4 Create fixture loading test helper
- **What**: Create `Tests/Helpers/FixtureLoader.swift` with a utility to load fixture files from the test bundle.
- **API**:
  ```swift
  enum FixtureLoader {
      static func claudeCodeFixture(_ name: String) throws -> Data
      static func codexFixture(_ name: String) throws -> Data
      static func claudeCodeFixturePath(_ name: String) throws -> String
  }
  ```
- **Update `Package.swift`**: Add fixture files as test resources if needed.
- **Verify**: Write a `@Test` that loads `simple-session.jsonl` and confirms it's non-empty.

### 1.5 Test AgentState enum behaviors
- **What**: Write tests in `Tests/BullpenTests/AgentStateTests.swift` (replace existing XCTest ones).
- **Test behaviors**:
  - Every state has a non-empty `displayLabel`
  - The enum has exactly 9 cases (guard rail)
  - States are `Sendable`, `Equatable`, `Hashable`
- **Do NOT test**: Internal enum raw values, case ordering, or other implementation details.

### 1.6 Test AgentInfo behaviors
- **What**: Write tests for `AgentInfo` model.
- **Test behaviors**:
  - Default initialization produces sensible values (state is `.idle`, agentType is set)
  - State and taskDescription are mutable
  - Two AgentInfo with different IDs are not equal
  - Two AgentInfo with the same ID are equal
  - Conforms to `Identifiable`, `Sendable`

### 1.7 Test AgentActivity behaviors
- **What**: Write tests for `AgentActivity` and `ActivityType`.
- **Test behaviors**:
  - Each `ActivityType` maps to the correct `AgentState` via its `agentState` property
  - Specifically: read/glob/grep → `.readingFiles`, write/edit → `.writingCode`, bash → `.runningCommand`, webSearch/webFetch → `.searching`, text → `.thinking`
  - `AgentActivity` can be constructed with all required fields

### 1.8 Test AgentLogReader protocol conformance
- **What**: Write a test that verifies `ClaudeCodeLogReader` and `CodexLogReader` conform to `AgentLogReader` protocol.
- **Test behavior**: Both types can be instantiated and assigned to a variable of type `any AgentLogReader`.

### 1.9 Scaffold tools/assetgen/ project
- **What**: Create `tools/assetgen/` as a TypeScript Node.js project mirroring the pattern from one-more-night.
- **Create**:
  - `tools/assetgen/package.json` — deps: `@ai-sdk/gateway`, `ai`, `commander`, `zod`, `dotenv`, `sharp`. devDeps: `typescript`, `tsx`, `@types/node`.
  - `tools/assetgen/tsconfig.json`
  - `tools/assetgen/src/index.ts` — CLI entry point with `generate` and `batch` commands
  - `tools/assetgen/src/generate.ts` — Core generation logic using `generateImage()`
  - `tools/assetgen/src/config.ts` — Art bible, type hints, asset manifest (empty for now)
  - `tools/assetgen/src/metadata.ts` — Sidecar `.meta.json` writer
  - `tools/assetgen/.env.example` — Template with `AI_GATEWAY_API_KEY=vck_...`
  - `tools/assetgen/.gitignore` — Ignore `.env`, `node_modules/`, `output/`
- **Verify**: `cd tools/assetgen && pnpm install && pnpm tsx src/index.ts --help` prints usage.

### 1.10 Define Bullpen art bible in assetgen config
- **What**: Write the art bible string in `tools/assetgen/src/config.ts`.
- **Art bible** (based on VISION.md Section 9):
  ```
  Style: 2D pixel art, 3/4 top-down perspective (RPG-style, like Stardew Valley or Game Dev Tycoon).
  Color palette: Warm, muted background tones (off-white walls #EAE6DF, tan wood floor #C4B6A0, brown desks #8B6544). Saturated accent colors for status indicators.
  Resolution: Character sprites 32x48 pixels, furniture/tiles 16x16 or 32x32 pixels, scaled with nearest-neighbor filtering.
  Outline: 1px dark outlines (#2D2D3D, warm dark — never pure black) on all sprites.
  Perspective: 3/4 top-down view for all elements.
  Lighting: Soft ambient lighting, warm office tones, no harsh directional shadows.
  Background: Transparent where applicable.
  Consistency: All assets must feel like they belong in the same cozy office environment.
  ```
- **Define type hints**: `character`, `furniture`, `tile`, `decoration`, `icon`
- **Verify**: Config exports ART_BIBLE string and type hints.

### 1.11 Define asset manifest in assetgen config
- **What**: Define `BULLPEN_ASSETS` array in `config.ts` listing every asset the app needs.
- **Character sprites** (32x48 each, per agent type):
  - `char_claude_idle`, `char_claude_thinking`, `char_claude_writing`, `char_claude_reading`, `char_claude_command`, `char_claude_searching`, `char_claude_waiting`, `char_claude_error`, `char_claude_finished`
  - Same 9 for `char_codex_*`
- **Furniture** (32x32):
  - `furniture_desk`, `furniture_chair`, `furniture_monitor_on`, `furniture_monitor_off`, `furniture_monitor_green`, `furniture_monitor_red`, `furniture_monitor_amber`
- **Decorations** (16x16 or 32x32):
  - `decor_plant_1`, `decor_plant_2`, `decor_coffee_mug`, `decor_clock`, `decor_window`, `decor_whiteboard`, `decor_lamp`
- **Tiles** (16x16):
  - `tile_floor_wood`, `tile_wall`
- **Office cat** (32x32):
  - `cat_idle`, `cat_walk_1`, `cat_walk_2`, `cat_sleep`
- **Verify**: Manifest is an array of objects with `{ name, type, description, aspectRatio }`.

### 1.12 Add .gitignore entries for assetgen
- **What**: Update root `.gitignore` to exclude `tools/assetgen/node_modules/`, `tools/assetgen/.env`, and `tools/assetgen/output/`.
- **Also**: Ensure `Assets/` directory (where generated PNGs will land) IS tracked.
- **Verify**: `git status` doesn't show node_modules or .env.

### 1.13 Verify full build after all foundation changes
- **What**: Run `swift build && swift test` and confirm:
  - Build succeeds with zero warnings (or only expected platform warnings)
  - All tests pass
  - No test is skipped or disabled
- **This is the milestone gate**: Do not proceed to Milestone 2 until this passes.

---

## Parallelism

The following tasks can be done in parallel:
- **[1.2, 1.3]** — Fixture files for Claude Code and Codex are independent
- **[1.5, 1.6, 1.7, 1.8]** — Model tests are independent of each other (but all depend on 1.1)
- **[1.9, 1.10, 1.11, 1.12]** — Asset gen scaffolding is independent of Swift test work
- **1.4** depends on 1.2 and 1.3 (needs fixture files to exist)
- **1.13** depends on everything above
