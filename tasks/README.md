# Bullpen — Task Breakdown

8 milestones, ~120 tasks total. Covers V1 MVP + V1.x Polish per VISION.md.

## Milestone Overview

| # | File | Tasks | Goal | Human Gate |
|---|------|-------|------|------------|
| 1 | [01-foundation-and-test-infra.md](01-foundation-and-test-infra.md) | 13 | Fix tests, create fixtures, scaffold assetgen tool | `swift test` passes |
| 2 | [02-log-readers.md](02-log-readers.md) | 14 | Implement Claude Code + Codex log parsers | Verify against real logs |
| 3 | [03-agent-monitor-service.md](03-agent-monitor-service.md) | 12 | Wire log readers → state machine → published agent list | Agents appear in service from real sessions |
| 4 | [04-office-scene-and-floating-window.md](04-office-scene-and-floating-window.md) | 16 | Floating window, SpriteKit scene, placeholder sprites at desks | See agents reacting to real sessions |
| 5 | [05-asset-generation.md](05-asset-generation.md) | 12 | Generate all pixel art via Vercel AI Gateway + FLUX | Review & approve generated art |
| 6 | [06-sprite-integration-and-animations.md](06-sprite-integration-and-animations.md) | 18 | Replace placeholders with pixel art, 9 animation states | Animations look good |
| 7 | [07-ui-and-interaction.md](07-ui-and-interaction.md) | 15 | Menu bar, detail popover, click interactions | Full V1 QA pass |
| 8 | [08-v1x-polish.md](08-v1x-polish.md) | 17 | Ambient animations, notifications, office cat | Ship it |

**Total: 117 tasks**

## Dependency Graph

```
Milestone 1 (Foundation)
├──→ Milestone 2 (Log Readers) ──→ Milestone 3 (Monitor Service) ──→ Milestone 4 (Office Scene) ──┐
│                                                                                                    │
└──→ Milestone 5 (Asset Generation) ─────────────────────────────────────────────────────────────────┤
                                                                                                     │
                                                                                           Milestone 6 (Sprites + Animations)
                                                                                                     │
                                                                                           Milestone 7 (UI & Interaction)
                                                                                                     │
                                                                                           Milestone 8 (V1.x Polish)
```

**Key parallelism**: Milestone 5 (asset generation) is independent of Milestones 2–4 and can run simultaneously. This is the biggest time savings — art generation happens while backend work progresses.

## Design Decisions Made

- **Testing framework**: Swift Testing (`@Test`, `#expect`) — modern, native to Swift 6
- **Test fixtures**: Static `.jsonl`/`.json` files checked into repo under `Tests/Fixtures/`
- **Visual testing**: Behavioral only (verify nodes, positions, actions) — no snapshot/pixel comparison
- **Art generation**: Vercel AI Gateway + `bfl/flux-kontext-max` via `tools/assetgen/` (TypeScript CLI)
- **Detail popover**: SwiftUI popover (native feel)
- **No CI**: Out of scope
- **No V2**: Scope ends at V1.x polish
