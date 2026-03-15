import SwiftUI
import Services

/// Main entry point for the Bullpen app.
/// A novelty macOS app that visualizes AI coding agent activity
/// as little sprite characters in a 2D office world.
@main
struct BullpenApp: App {
    @StateObject private var monitorService = AgentMonitorService()

    var body: some Scene {
        WindowGroup {
            ContentView(monitorService: monitorService)
                .onAppear {
                    monitorService.startMonitoring()
                }
                .onDisappear {
                    monitorService.stopMonitoring()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1024, height: 768)
    }
}
