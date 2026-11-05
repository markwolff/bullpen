# Contributing to Bullpen

Thanks for helping improve Bullpen! This guide covers how to get the project
building locally, how to run the test suite, and what to do when you are ready
to open a pull request.

## Setup

Bullpen is a macOS menu bar app (SwiftUI + SpriteKit), so development requires:

- **macOS 15 (Sequoia) or newer** — declared in `Package.swift`
- **Swift 6.2 toolchain** (Xcode 26 or a matching open-source toolchain) —
  the package uses `swift-tools-version: 6.2`

There is no Linux support: the app links against AppKit, SpriteKit, and
UserNotifications.

```bash
git clone https://github.com/markwolff/bullpen.git
cd bullpen
swift build            # resolves dependencies (pinned in Package.resolved) and builds all targets
swift run BullpenApp   # run from the terminal
```

To exercise the real menu bar behavior, build and launch a proper `.app`
bundle instead — macOS only registers `NSStatusItem` and the accessory
activation policy for bundled apps:

```bash
./run.sh               # build the bundle and launch it
./run.sh --build-only  # build the bundle without launching
```

The package is split into five targets with strict layering — `Models` →
`LogReaders` → `Services` → `SpriteWorld` → `BullpenApp`. A lower target must
never import a higher one; see `CLAUDE.md` for the full architecture notes and
code conventions, and `VISION.md` for the product spec.

## Running tests

The suite uses [Swift Testing](https://github.com/swiftlang/swift-testing)
(`@Test` / `#expect`), not XCTest. Run everything before you push:

```bash
swift test                                            # full suite
swift test --filter AgentMonitorServiceTests          # one suite
swift test --filter AgentMonitorServiceTests/testName # one test
swift build --build-tests                             # compile tests without running them
```

Notes:

- Test fixtures live in `Tests/Fixtures/` (`ClaudeCode/`, `Codex/`,
  `Scenarios/`, `VisualBaselines/`) and are resolved by `FixtureLoader` via
  `#filePath`, so no bundle resources are needed.
- Use `MockLogReader` for service tests instead of touching the file system,
  and mark tests that reach UI/service types with `@MainActor`.
- Scenario fixtures are generated: regenerate them with
  `tools/compile-scenarios.sh` after changing the scenario compiler.
- Deterministic rendering guardrails compare screenshots against the committed
  baselines in `Tests/Fixtures/VisualBaselines/`:

  ```bash
  tools/guardrails.sh fast   # build, snapshot tests, single baseline render
  tools/guardrails.sh full   # whole suite, coverage, all renders, app smoke test
  ```

  `tools/guardrails.sh full` launches the app bundle, so run it from a logged-in
  macOS GUI session.
- CI (`.github/workflows/ci.yml`) runs `swift build --build-tests` and
  `swift test` on `macos-latest` for every push and pull request. A red CI run
  blocks review, so keep the suite green.

## Opening a PR

1. Branch off `main` and keep each PR focused on a single change.
2. Match the existing commit style: a short, imperative, sentence-case summary
   (for example, `Add a living office world that scales with agent count`).
3. Run `swift test` locally — and `tools/guardrails.sh fast` if you touched
   sprites, layouts, or rendering — before pushing.
4. Update the docs that your change affects: `README.md` for user-facing
   behavior, `CLAUDE.md` for architecture or conventions, and the milestone
   checklists in `tasks/`.
5. Push your branch and open the PR:

   ```bash
   git push -u origin my-branch
   gh pr create --fill
   ```

6. In the PR description, explain what changed, why, and how you verified it
   (commands run, screenshots for visual changes).
7. Make sure the `ci` workflow passes, then request review. Please keep the PR
   up to date with `main` if review takes a while.
