# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

macOS menu bar app (Swift 6.2 + SwiftUI + SpriteKit) that visualizes AI coding agent activity as pixel-art sprites in a 2D office scene. Monitors Claude Code and Codex CLI logs in real-time.

## Build & Run

```bash
swift build                # Build all targets
swift run BullpenApp       # Run the app
swift test                 # Run all tests
swift test --filter AgentMonitorServiceTests          # Run one test suite
swift test --filter AgentMonitorServiceTests/testName # Run a single test
```

Requires macOS 15+ and Swift 6.2 toolchain.

## Architecture

Five SPM targets with strict dependency layering (lower targets cannot import higher ones):

```
BullpenApp (SwiftUI entry point, AppDelegate, ContentView)
    ├── SpriteWorld (OfficeScene, AgentSprite, CatSprite, textures)
    │       ├── Models
    │       └── Services
    ├── Services (AgentMonitorService, LogWatcher, NotificationService)
    │       ├── Models
    │       └── LogReaders
    ├── LogReaders (AgentLogReader protocol + Claude/Codex implementations)
    │       └── Models
    └── Models (AgentInfo, AgentState, AgentActivity — pure data, no deps)
```

### Data Flow

Log files on disk → `LogWatcher` (FSEvents/GCD) detects changes → `AgentLogReader` parses new bytes → `AgentMonitorService` updates `@Published agents: [AgentInfo]` → `ContentView` passes agents to `OfficeScene.updateAgents(_:)` → `AgentSprite` updates animation, thought bubble, status indicator.

### Concurrency Model

- `@MainActor` on services and UI types (`AgentMonitorService`, `NotificationService`, `AppDelegate`)
- `async/await` for log reading and session discovery
- GCD `DispatchSource` for file system watching, dispatching to main via `Task { @MainActor in ... }`
- All model types conform to `Sendable`

## Code Conventions

- Explicit `public` access on module APIs, default internal otherwise
- `// MARK: -` for section organization; `///` doc comments on public APIs
- Error handling: throws with silent fallback — malformed data skipped, failures return empty arrays
- Texture names as static constants in `TextureManager` (e.g., `TextureManager.furnitureDesk`)
- Dependency injection via protocols (e.g., `AgentLogReader`) and init parameters
- Node naming convention in SpriteKit: `"desk_\(id)"`, `"monitor_\(id)"`, `"agent_\(id)"`, `"decoration_\(name)"` — used for lookup via `childNode(withName:)`

## SpriteKit-Specific Patterns

**Textures are programmatically generated** — `PixelArtGenerator` creates all pixel-art textures at runtime (no PNG assets). `TextureManager` is a singleton that caches them. When adding new visual elements, add a static constant to `TextureManager` and a generator method to `PixelArtGenerator`.

**zPosition layering** (lower = further back):
- `-12` to `-10`: Background tiles (wall, floor) in `background_container`
- `-8` to `-6`: Rug, trim
- `1–4`: Furniture (desks, monitors, lamps, glows, steam)
- `5`: Agent sprites
- `10`: UI labels
- `50+`: Particle effects (dust motes)

**Pixel art scales**: Source textures are small (8x8 to 32x48 pixels) scaled up 3-5x with `.nearest` filtering for crisp edges. Character sprites are 16x24 scaled 3x = 48x72 display points.

## Idle Behavior System

`IdleBehaviorManager` drives a per-agent state machine (`atDesk` → `walkingToActivity` → `performing` → `walkingBack`) with random delays. Ten roaming behaviors (water cooler, bookshelf, pet cat, etc.) each with target positions defined in `OfficeLayout`. The scene's `update(_:)` loop calls `updateIdleBehavior(for:deltaTime:)` each frame for idle agents.

## Testing

Uses **Swift Testing** (`@Test`, `#expect`), not XCTest.

- Test fixtures in `Tests/Fixtures/ClaudeCode/` (`.jsonl`) and `Tests/Fixtures/Codex/` (`.json`)
- `FixtureLoader` resolves fixture paths via `#filePath` (no bundle resources)
- `MockLogReader` for service tests without file system dependencies
- Helper functions like `makeScene()`, `makeAgent()` for test setup
- `@MainActor` on tests that touch UI/service types

## Key References

| File | Role |
|------|------|
| `VISION.md` | Full product spec — personas, features, visual design, log schemas |
| `tasks/` | 8-milestone task breakdown (~120 tasks) with completion tracking |
