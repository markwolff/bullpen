# Contributing to Bullpen

Bullpen is a macOS menu bar app (Swift 6.2 + SwiftUI + SpriteKit) that
visualizes AI coding agent activity as pixel-art sprites in a 2D office scene.
Thanks for helping out — this guide covers everything you need to get set up,
run the tests, and get a change merged.

## Setup

**Requirements**

- macOS 15 (Sequoia) or newer — the package declares `.macOS(.v15)`
- Xcode with the Swift 6.2 toolchain (`swift-tools-version: 6.2`)
- Command line tools on `PATH` (`swift`, `git`, and `gh` for releases)

**Get the code and build it**

```bash
git clone https://github.com/markwolff/bullpen.git
cd bullpen
swift build            # resolves SwiftPM dependencies and builds all targets
swift run BullpenApp   # run the app straight from SwiftPM
```

For the real menu bar experience (`NSStatusItem`, activation policy, no Dock
icon) launch it as an app bundle instead:

```bash
./run.sh               # build the bundle and launch it
./run.sh --build-only  # build .build/Bullpen.app without launching
```

**Project layout** — five SPM targets with strict dependency layering; a lower
layer must never import a higher one:

```
BullpenApp (SwiftUI entry point, AppDelegate, ContentView)
    ├── SpriteWorld (OfficeScene, AgentSprite, CatSprite, textures)
    ├── Services    (AgentMonitorService, LogWatcher, NotificationService)
    ├── LogReaders  (AgentLogReader protocol + Claude/Codex implementations)
    └── Models      (AgentInfo, AgentState, AgentActivity — pure data, no deps)
```

Two helper executables also live in `Sources/`: `BullpenScenarioCompiler`
(compiles fixture logs into scenario snapshots) and `BullpenScreenshot`
(deterministic scene renders). See [CLAUDE.md](CLAUDE.md) for architecture,
concurrency, and code-convention details, and [VISION.md](VISION.md) for the
product spec.

## Running tests

The suite uses [Swift Testing](https://github.com/swiftlang/swift-testing)
(`@Test`, `#expect`), **not** XCTest.

```bash
swift test                                             # full suite
swift test --filter AgentMonitorServiceTests           # one suite
swift test --filter AgentMonitorServiceTests/testName  # one test
swift test --enable-code-coverage                      # with coverage
```

Heavier guardrails, including deterministic screenshot renders compared against
the checked-in baselines in `Tests/Fixtures/VisualBaselines/`, run through:

```bash
tools/guardrails.sh fast   # build, snapshot + bootstrap tests, one render
tools/guardrails.sh full   # build, full suite, coverage, all renders, app smoke test
```

Notes for writing tests:

- Fixtures live in `Tests/Fixtures/ClaudeCode/` (`.jsonl`),
  `Tests/Fixtures/Codex/` (`.json`/`.jsonl`), and `Tests/Fixtures/Scenarios/`.
  `FixtureLoader` resolves them via `#filePath`, so no bundle resources needed.
- Use `MockLogReader` for service tests instead of touching the file system.
- Mark tests that touch UI, scene, or service types with `@MainActor`; scene
  tests present the scene to a headless `SKView` via the `makeScene()` helper.
- If you change scene behavior, add or update coverage for the visual/state
  contract (node names like `desk_<id>`, `agent_<id>`, positions, actions).

CI runs `swift build` and `swift test` on a macOS runner for every push and pull
request — see [.github/workflows/ci.yml](.github/workflows/ci.yml). Please make
sure `swift test` is green locally before you push.

## Opening a PR

1. **Branch** off `main` with a short, descriptive name:
   `git checkout -b fix-codex-subagent-parsing`.
2. **Keep the change focused.** Follow the existing conventions: explicit
   `public` on module APIs, `// MARK: -` sections, `///` doc comments on public
   APIs, dependency injection through protocols, and the target layering above.
3. **Add tests** for new behavior or bug fixes, and update `README.md`,
   `CLAUDE.md`, or `tasks/` when your change affects usage or scope.
4. **Run the suite** before pushing:
   ```bash
   swift build
   swift test
   ```
   Run `tools/guardrails.sh full` as well when you touch rendering, sprites, or
   scene layout. If a visual baseline legitimately changes, regenerate and
   commit the files under `Tests/Fixtures/VisualBaselines/`.
5. **Write clear commits.** Imperative, sentence-case subjects, e.g.
   `Refactor log handling and world resets`.
6. **Open the pull request** against `main`:
   ```bash
   git push -u origin <your-branch>
   gh pr create --fill
   ```
   Describe what changed and why, how you verified it, and include a screenshot
   or short recording for any visible scene or UI change.
7. **Get CI green.** The `ci` workflow must pass before review; push follow-up
   commits to the same branch to fix failures, and keep the discussion in the PR
   so the final state is reviewable.
