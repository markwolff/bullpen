# Contributing to Bullpen

Bullpen is a macOS menu bar app (Swift 6.2 + SwiftUI + SpriteKit) that visualizes
AI coding agent activity as pixel-art sprites in a 2D office scene. This guide
covers local setup, running the tests, and opening a pull request.

## Setup

Requirements:

- **macOS 15 (Sequoia) or newer** — the app depends on AppKit, SwiftUI, and SpriteKit
- **Swift 6.2 toolchain** (Xcode with a Swift 6.2 compiler); `Package.swift` declares
  `swift-tools-version: 6.2` and the package targets `.macOS(.v15)`
- `git`, plus the [GitHub CLI](https://cli.github.com) (`gh`) if you want to open PRs
  from the terminal

Clone and build:

```bash
git clone https://github.com/markwolff/bullpen.git
cd bullpen
swift build
```

The only external dependency is
[swift-testing](https://github.com/swiftlang/swift-testing), pinned in
`Package.resolved`; SwiftPM fetches it on the first build.

Run the app while developing:

```bash
swift run BullpenApp    # fastest iteration loop
./run.sh                # build and launch a real .app bundle
./run.sh --build-only   # build .build/Bullpen.app without launching
```

Use the `.app` bundle whenever you touch menu bar behavior — `NSStatusItem` and the
`LSUIElement` activation policy only behave correctly from a bundled app.

Bullpen reads agent logs from `~/.claude` (Claude Code) and `~/.codex` (Codex CLI),
so keep one of those agents running to see sprites appear. Both log readers accept a
custom directory, which is how tests stay off your real logs.

Targets are strictly layered — a lower target must never import a higher one:

```
BullpenApp → SpriteWorld → Services → LogReaders → Models
```

`Models` has no dependencies; put pure data types there. See `CLAUDE.md` for the full
architecture notes and code conventions, and `VISION.md` for the product spec.

## Running tests

The suite uses [Swift Testing](https://github.com/swiftlang/swift-testing)
(`@Test` / `#expect`), not XCTest.

```bash
swift test                                            # full suite (~400 tests)
swift build --build-tests                             # compile tests without running them
swift test --filter AgentMonitorServiceTests          # one suite
swift test --filter AgentMonitorServiceTests/example  # one test
swift test --enable-code-coverage                     # with coverage
```

When adding tests:

- Put fixtures in `Tests/Fixtures/ClaudeCode/` (`.jsonl`) and `Tests/Fixtures/Codex/`
  (`.json`), and load them through `FixtureLoader`, which resolves paths via `#filePath`
  (no bundle resources).
- Use `MockLogReader` for service tests instead of touching the file system.
- Mark tests that touch UI or service types `@MainActor`.
- Test observable behavior, not implementation details.

If you change SpriteKit scenes, layouts, or textures, also run the visual guardrails:

```bash
tools/guardrails.sh fast   # snapshot + bootstrap tests and one baseline render
tools/guardrails.sh full   # whole suite, coverage, every baseline render, app smoke test
```

Guardrails render scenarios with `BullpenScreenshot` and compare the output against
`Tests/Fixtures/VisualBaselines`. Only refresh a baseline when the visual change is
intentional, and say so in the PR description.

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs
`swift build --build-tests` and `swift test` on a macOS runner for every push and pull
request, so the full suite has to be green before a change can merge.

## Opening a PR

1. Branch off `main` with a short topic branch:
   `git checkout -b yourname/short-topic`.
2. Keep the change focused, and write imperative commit subjects — e.g.
   `Fix app launch crash when menuBarPanel mode is persisted`.
3. Update docs next to the code: `README.md` for user-facing commands, `CLAUDE.md`
   for architecture or conventions, `tasks/*.md` for milestone tracking.
4. Make sure `swift build` and `swift test` pass locally (plus
   `tools/guardrails.sh fast` for visual changes) before you push.
5. Push the branch and open the PR:

   ```bash
   git push -u origin yourname/short-topic
   gh pr create --base main --title "Short imperative title" --body "..."
   ```

6. In the description, explain what changed and why, and list how you tested it —
   the commands you ran and any tests you added.
7. Confirm CI is green (`gh pr checks --watch`) and fix any failure before asking for
   review.
8. Once the PR is approved and green, merge it into `main` and delete the branch.
