# Unique World Layouts Design

## Summary

Replace the 5 color-only world presets with 3 fully unique worlds, each with its own room layout, desk arrangement, furniture, decorations, textures, and points of interest. Introduce a `WorldLayout` protocol so the scene builder is generic and any future world can be added by creating a new conforming type.

## Three Worlds

1. **Classic Bullpen** — Warm, cozy startup office with 6 rooms, desks in rows, coffee station, ping pong table
2. **Zen Studio** — Japanese workspace with tatami, shoji screens, koi pond courtyard, low chabudai tables, tea room
3. **Overgrown Ruins** — Post-apocalyptic tech lab consumed by nature: vines on server racks, tree through ceiling, bioluminescent mushrooms

## Architecture: WorldLayout Protocol

Each world conforms to a `WorldLayout` protocol providing all geometry, furniture, and POIs. The scene builder is generic.

### New Types

**`POICategory`** enum (in Models):
- `.refreshment`, `.relaxation`, `.creative`, `.knowledge`, `.nature`, `.social`, `.utility`, `.pet`

**`PointOfInterest`** struct (in Models):
- `id: String`, `category: POICategory`, `label: String`, `emoji: String`
- `position: CGPoint`, `capacity: Int`, `animationHint: POIAnimationHint`

**`POIAnimationHint`** enum: `.stand`, `.sit`, `.inspect`, `.interact`, `.kneel`, `.pace`

**`DecorationSpec`** struct: `textureName: String`, `position: CGPoint`, `size: CGSize`, `zPosition: CGFloat`

**`RugSpec`** struct: `position: CGPoint`, `size: CGSize`, `cornerRadius: CGFloat`, `colorSlot: RugColorSlot`

**`WorldLayout`** protocol:
- `sceneSize: CGSize` (always 1280x768)
- `walkableArea: CGRect`
- `rooms: [RoomDefinition]`
- `tables: [TableDefinition]`
- `desks: [DeskPosition]` (derived from tables)
- `barriers: [Barrier]`
- `pointsOfInterest: [PointOfInterest]`
- `decorations: [DecorationSpec]`
- `rugs: [RugSpec]`
- `aisleYPositions: [CGFloat]`, `corridorXPositions: [CGFloat]`
- `doorPosition: CGPoint`, `doorExitPosition: CGPoint`
- Pet positions (optional, with defaults)

### POI Registry

`POIRegistry` (@MainActor class) manages live POI state:
- Registers static POIs from world layout at build time
- Updates dynamic POIs (cat/dog) each frame
- Tracks occupancy per POI (claim/release)
- Provides `availablePOIs()` for idle behavior selection

### Procedural Idle Behaviors

Replace hardcoded `IdleBehavior` enum with POI-driven selection:
- Agent picks from available POIs using weighted random selection
- Category-based variety filter (avoids repeating last 3 categories)
- Capacity-based occupancy (replaces 60px proximity check)
- Animation hint drives posture (6 hints cover all cases)
- Deep thinking pacing uses geometry-derived waypoints (already world-agnostic)

### World Switching

Switching worlds is a full restart: `applyWorld()` clears everything and rebuilds from the new layout. No state preservation needed.

## Per-World Floorplans

### Classic Bullpen (28 desks)

6 rooms: Focus Studio, Recreation Lounge, Circulation Spine, Gallery, Collaboration Room, Build Room. Same layout as current app — this is the "home" world.

### Zen Studio (28 desks)

6 areas: Meditation Garden, Tea Room, Koi Pond Courtyard, Engawa (Veranda), Main Work Hall, Scroll Library. Central koi pond with stone bridge. Low tables with zabuton cushions. Shoji screens instead of glass walls.

### Overgrown Ruins (28 desks)

6 areas: Greenhouse Breach, Collapsed Wing, The Big Tree (atrium), Mushroom Grove, Rooftop Opening, Server Room (vine-covered). Massive tree through center. Bioluminescent mushrooms. Crumbling walls with nature poking through.

## Pixel Art

All textures are programmatically generated in `PixelArtGenerator` — Stardew Valley style. Each world gets its own texture generation methods for world-specific items (koi, mushrooms, torii gate, vines, etc.). Significant effort on making each world's pixel art beautiful and distinctive.

## File Changes

**New files:**
- `Sources/Models/POICategory.swift`
- `Sources/Models/PointOfInterest.swift`
- `Sources/SpriteWorld/WorldLayout.swift` (protocol + supporting types)
- `Sources/SpriteWorld/POIRegistry.swift`
- `Sources/SpriteWorld/Layouts/ClassicBullpenLayout.swift`
- `Sources/SpriteWorld/Layouts/ZenStudioLayout.swift`
- `Sources/SpriteWorld/Layouts/OvergrownRuinsLayout.swift`

**Modified files:**
- `Sources/Models/WorldPreset.swift` — 3 presets instead of 5
- `Sources/SpriteWorld/WorldTheme.swift` — 3 themes instead of 5
- `Sources/SpriteWorld/OfficeScene.swift` — Generic scene builder using WorldLayout protocol
- `Sources/SpriteWorld/IdleBehavior.swift` — POI-driven selection
- `Sources/SpriteWorld/AgentSprite.swift` — Animation hint support
- `Sources/SpriteWorld/PixelArtGenerator.swift` — Per-world texture methods
- `Sources/SpriteWorld/TextureManager.swift` — New texture constants
- `Sources/BullpenApp/WorldMenuOverlay.swift` — 3 items instead of 5
- Tests updated accordingly
