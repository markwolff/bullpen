# Bird Cage, Barista NPC, and Office Decorations

**Date**: 2026-03-15
**Status**: Approved

## Overview

Add three categories of new content to the office scene: an animated bird cage decoration, an interactive barista NPC that agents visit for coffee, and several static decorations to make the office feel more lived-in.

## 1. Bird Cage (Animated Decoration)

### Textures (`PixelArtGenerator`)
- `birdCage()` — 16x24 pixel source: rounded dome cage with vertical bars, small perch, base tray
- `birdIdle(frame:)` — 6x6 pixel source, 3 frames: head bob (frame 0), wing flutter up (frame 1), wing flutter down (frame 2)
- Colors: `cageGold` (#C8A850), `cageBars` (#A08840), `birdYellow` (#F8D830), `birdWing` (#E8C020), `birdBeak` (#F08030)

### TextureManager
- `decorationBirdCage = "decoration_bird_cage"`
- Frame keys: `"bird_idle_frame0"`, `"bird_idle_frame1"`, `"bird_idle_frame2"`
- Add all to `allTextureNames` and `generatePixelArt(for:)` dispatch

### BirdCageSprite (new file: `Sources/SpriteWorld/BirdCageSprite.swift`)
- Subclass of `SKNode` (follows `RadioSprite` pattern)
- `body: SKSpriteNode` — cage texture, size 48x72 (3x scale)
- `birdSprite: SKSpriteNode` — positioned inside cage, size 18x18, runs repeating 3-frame animation (0.4s per frame)
- `startChirp()` — spawns `"♪"` `SKLabelNode` that drifts up 30pt and fades out over 1.5s; triggered randomly every 5-15s
- `update(hasActiveAgents:)` — when active agents exist, chirp frequency increases (every 3-8s)

### Placement
- `OfficeLayout.birdCagePosition` — `CGPoint(x: 1050, y: sceneSize.height - 75)` (back wall, between bulletin board and achievement shelf)
- `OfficeScene`: add `private var birdCageSprite: BirdCageSprite?`, instantiate in `setupFeatureDecorations()`, call `update(hasActiveAgents:)` from `update(_:)` loop
- zPosition: 2 (furniture layer)

## 2. Barista NPC (Interactive)

### Textures (`PixelArtGenerator`)
- `baristaIdle(frame:)` — 16x24 pixel source, 2 frames: standing with cloth (frame 0), wiping motion (frame 1)
- `baristaServe()` — 16x24 pixel source: arm extended with cup
- `coffeeStation()` — 32x24 pixel source: counter with espresso machine, steam wisps
- Colors: `baristaApron` (#4A7A4A), `baristaHair` (#3A2A1A), `barista skin` (#E8C8A0), `espressoMachine` (#606060), `counterTop` (#8B7355)

### TextureManager
- `decorationCoffeeStation = "decoration_coffee_station"`
- `baristaIdleFrame0/1`, `baristaServe`
- Add all to `allTextureNames` and dispatch

### BaristaSprite (new file: `Sources/SpriteWorld/BaristaSprite.swift`)
- Subclass of `SKNode`
- `bodySprite: SKSpriteNode` — barista character, size 48x72 (3x)
- `stationSprite: SKSpriteNode` — coffee station behind barista, size 96x72 (3x)
- Idle: repeating 2-frame wiping animation (0.8s per frame)
- `serveCustomer()` — switches to serve texture for 1.5s, spawns small steam particle, then returns to idle
- Optional: small `"☕"` emoji floats up during serve

### Integration with CoffeeRunManager
- Modify `CoffeeRunManager` or `OfficeScene` coffee run flow: agents walk to `baristaStandPosition` instead of `coffeeMachinePosition`
- When agent arrives, call `baristaSprite.serveCustomer()`, wait 1.5s, then agent walks back with cup
- The existing cup-on-desk logic remains unchanged

### Placement
- `OfficeLayout.coffeeStationPosition` — `CGPoint(x: 100, y: 345)` (left wall, aisle between tables)
- `OfficeLayout.baristaStandPosition` — `CGPoint(x: 100, y: 330)` (in front of station)
- `OfficeLayout.baristaCustomerPosition` — `CGPoint(x: 140, y: 330)` (where agent stands to order)
- `OfficeScene`: add `private var baristaSprite: BaristaSprite?`, setup in `setupFeatureDecorations()`, no per-frame update needed (event-driven via serve)

## 3. Extra Static Decorations

### Wall Clock
- Texture: `wallClock(frame:)` — 10x10, 2 frames (minute hand at 12, minute hand at 3)
- TextureManager: `decorationWallClock`, frame keys `"wall_clock_frame0/1"`
- Placement: back wall at `(800, sceneSize.height - 75)`, between windows. Size 40x40 (4x). 2-frame animation, 30s per frame.

### Motivational Poster
- Texture: `motivationalPoster()` — 14x18, simple frame with colorful abstract art inside
- TextureManager: `decorationPoster`
- Placement: left wall at `(30, 500)`. Size 56x72 (4x). Static, zPosition 2.

### Coat Hooks
- Texture: `coatHooks()` — 20x14, wall-mounted rack with 2-3 hanging jackets in different colors
- TextureManager: `decorationCoatHooks`
- Placement: right wall near door at `(1230, 500)`. Size 60x42 (3x). Static, zPosition 2.

### Coffee Station Rug
- Texture: `smallRug()` — 24x12, warm-colored area rug
- TextureManager: `decorationSmallRug`
- Placement: under the coffee station at `(110, 330)`. Size 96x48 (4x). zPosition: -6 (rug layer).

## File Changes Summary

| File | Change |
|------|--------|
| `PixelArtGenerator.swift` | Add ~10 new texture methods + color constants |
| `TextureManager.swift` | Add ~12 new static constants, allTextureNames entries, dispatch branches |
| `BirdCageSprite.swift` | New file — SKNode subclass with animated bird |
| `BaristaSprite.swift` | New file — SKNode subclass with serve interaction |
| `OfficeLayout.swift` | Add 4 new position properties |
| `OfficeScene.swift` | Add sprite references, setup calls, update loop integration |
| `CoffeeRunManager.swift` | Minor: agents route to barista position (or OfficeScene handles routing change) |
