# Bullpen overview
- Purpose: macOS SwiftUI + SpriteKit app that visualizes coding agents as office workers moving through a shared office scene.
- Stack: Swift 6.2 package, SwiftUI app target (`BullpenApp`), SpriteKit rendering in `SpriteWorld`, model types in `Models`, log ingestion in `LogReaders`, app/services in `Services`, tests with `swift-testing`.
- Structure: `Sources/BullpenApp` UI shell, `Sources/SpriteWorld` office scene/sprites/managers, `Sources/Models` agent state/domain types, `Sources/LogReaders` session/log parsing, `Sources/Services` monitoring and notifications, `Tests/BullpenTests` coverage.
- Platform: macOS 15.
