# Contributing to Bullpen

Thanks for helping out! Bullpen is a macOS menu bar app (Swift 6.2 + SwiftUI +
SpriteKit) that visualizes AI coding agent activity as pixel-art sprites. This
guide covers the three things you need to get work merged: setting up, running
the tests, and opening a pull request.

## Setup

**Requirements**

- macOS 15 (Sequoia) or newer — the package declares `.macOS(.v15)` and depends
  on AppKit/SpriteKit, so the app cannot be built or tested on Linux.
- Xcode with the Swift 6.2 toolchain (`swift-tools-version: 6.2`). Verify with
  `swift --version`.
- Command Line Tools selected: `xcode-select -p` should point at your Xcode.

**Clone and build**

```bash
git clone https://github.com/markwolff/bullpen.git
cd bullpen
swift build            # resolves dependencies and builds all targets
```

**Run the app**

```bash
swift run BullpenApp   # quick iteration from the terminal
./run.sh               # build + launch a real .app bundle (menu bar item, LSUIElement)
./run.sh --build-only  # build the bundle without launching it
```

Use `./run.sh` when you touch anything menu-bar or window related: macOS only
treats Bullpen as a proper GUI app when it is launched from a bundle.

**Project layout**

Five SPM targets with strict layering — a target may only import the ones below
it:

```
BullpenApp → SpriteWorld → Services → LogReaders → Models
```

`Models` has no dependencies. Keep new code in the lowest layer that makes
sense, and see [CLAUDE.md](CLAUDE.md) for architecture details and code
conventions (`// MARK: -` sections, `///` docs on public API, explicit `public`
on module boundaries, dependency injection via protocols).

## Running tests

The suite uses [Swift Testing](https://github.com/swiftlang/swift-testing)
(`@Test`, `#expect`, `@Suite`) — not XCTest.

```bash
swift test                                            # full suite
swift test --filter AgentMonitorServiceTests          # one suite
swift test --filter AgentMonitorServiceTests/testName # one test
swift build --build-tests                             # compile tests without running them
```

Notes:

- Tests must run on macOS. Anything touching `SpriteWorld` needs SpriteKit, so
  there is no Linux fallback — CI uses a macOS runner for the same reason.
- Fixtures live in `Tests/Fixtures/` (`ClaudeCode/*.jsonl`, `Codex/*.json`,
  `Scenarios/*.json`, `VisualBaselines/`) and are resolved by `FixtureLoader`
  via `#filePath`, not bundle resources.
- Use `MockLogReader` for service tests instead of touching the file system, and
  mark tests that reach UI/service types with `@MainActor`.
- If you change scenario definitions, regenerate the compiled scenarios:

  ```bash
  tools/compile-scenarios.sh
  ```

- Visual/behavioral guardrails (scenario renders compared against
  `Tests/Fixtures/VisualBaselines/`, plus an app launch smoke test):

  ```bash
  tools/guardrails.sh fast   # build, snapshot tests, one baseline render
  tools/guardrails.sh full   # full suite + coverage + all renders + smoke test
  ```

  Run `fast` while iterating on scene or sprite code, and `full` before opening
  a PR that changes rendering. Only update files in `VisualBaselines/` when the
  visual change is intentional, and call it out in the PR.

## Opening a PR

1. Branch off `main` with a descriptive name, matching the existing history —
   `<your-handle>/<short-topic>`, e.g. `markwolff/fix-agent-flicker`.
2. Keep the change focused, follow the layering rules above, and add or update
   tests alongside the code. Update `README.md`, `CLAUDE.md`, or `tasks/` when
   behavior or workflows change.
3. Write short, imperative commit subjects (e.g. `Refactor log handling and
   world resets`). Don't commit build output — `.build/` and friends are
   gitignored.
4. Verify locally before pushing:

   ```bash
   swift build
   swift test
   tools/guardrails.sh fast   # when the scene, sprites, or scenarios changed
   ```

5. Push the branch and open the PR:

   ```bash
   git push -u origin <your-branch>
   gh pr create --fill
   ```

6. In the description, say what changed and why, how you tested it, and attach a
   screenshot or short clip for visual changes.
7. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) builds and runs the
   full test suite on macOS for every push and pull request. It must be green
   before review; check it with `gh pr checks` and push fixes to the same
   branch. Release packaging, signing, and notarization run separately from
   [.github/workflows/release-macos.yml](.github/workflows/release-macos.yml)
   on tag pushes.
