# Bullpen

macOS menu bar app (Swift 6.2 + SwiftUI + SpriteKit) that visualizes AI coding agent activity as pixel-art sprites in a 2D office scene. Monitors Claude Code and Codex CLI logs in real-time.

## Build & Run

```bash
swift build          # Build all targets
swift run BullpenApp # Run the app
swift test           # Run tests (Swift Testing framework)
```

Requires macOS 15+ and Swift 6.2 toolchain.

## Architecture

Five SPM targets with strict dependency layering:

1. **Models** — Pure data types (`AgentInfo`, `AgentState`, `AgentActivity`), no dependencies
2. **LogReaders** — `AgentLogReader` protocol + implementations (`ClaudeCodeLogReader`, `CodexLogReader`), depends on Models
3. **Services** — `AgentMonitorService` (orchestrator), `LogWatcher`, `NotificationService`, depends on Models + LogReaders
4. **SpriteWorld** — `OfficeScene`, `AgentSprite`, `CatSprite`, texture management, depends on Models + Services
5. **BullpenApp** — SwiftUI entry point, `AppDelegate`, `ContentView`, depends on all

## Concurrency Model

- `@MainActor` on services and UI types (`AgentMonitorService`, `NotificationService`, `AppDelegate`)
- `async/await` for log reading and discovery
- GCD `DispatchSource` for file system watching, dispatching to main via `Task { @MainActor in ... }`
- All model types conform to `Sendable`

## Code Conventions

- Standard Swift naming: CamelCase types, camelCase properties/methods
- Explicit `public` access on module APIs, default internal otherwise
- `// MARK: -` for section organization
- `///` doc comments on public APIs
- Error handling: throws with silent fallback — malformed data skipped, failures return empty arrays
- Texture names as static constants in `TextureManager`
- Dependency injection via protocols (e.g., `AgentLogReader`) and init parameters

## Testing

Uses **Swift Testing** (`@Test`, `#expect`), not XCTest.

```swift
@Test func agentCreationFromDiscovery() async throws { ... }
```

- Test fixtures in `Tests/Fixtures/` (`.jsonl`, `.json` files)
- `MockLogReader` for service tests, `FixtureLoader` for test resources
- Helper functions like `makeScene()`, `makeAgent()` for test setup
- `@MainActor` on tests that touch UI/service types

## Key Files

| File | Role |
|------|------|
| `Package.swift` | SPM manifest, targets, dependencies |
| `VISION.md` | Product spec, personas, design principles |
| `tasks/` | 8-milestone task breakdown (~120 tasks) |
| `Sources/Services/AgentMonitorService.swift` | Core orchestrator, state machine |
| `Sources/SpriteWorld/OfficeScene.swift` | Main SpriteKit scene, sprite layout |
| `Sources/SpriteWorld/TextureManager.swift` | Asset loading, caching, fallback generation |
