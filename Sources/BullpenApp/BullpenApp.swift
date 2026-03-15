import SwiftUI
import SpriteKit
import SpriteWorld
import Services
import Combine
import AppKit

/// Main entry point for the Bullpen app.
/// A novelty macOS app that visualizes AI coding agent activity
/// as little sprite characters in a 2D office world.
@main
struct BullpenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 512, height: 384)
    }
}

/// App delegate that configures the floating borderless window and manages
/// frame rate tiering based on app activation state.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (no dock icon) — task 4.12
        NSApplication.shared.setActivationPolicy(.accessory)

        // Configure window after short delay to let SwiftUI create it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureMainWindow()
            self.setupFrameRateTiering()
        }
    }

    /// Configures the main window as a floating, borderless, transparent overlay.
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = true
    }

    /// Sets up frame rate tiering — task 4.13
    /// - Active: 30 FPS
    /// - Inactive: 10 FPS
    /// - Occluded: pause scene
    private func setupFrameRateTiering() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.setFrameRate(30)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                self?.setFrameRate(10)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.didChangeOcclusionStateNotification)
            .sink { [weak self] notification in
                guard let window = notification.object as? NSWindow else { return }
                self?.handleOcclusionChange(window: window)
            }
            .store(in: &cancellables)
    }

    private func setFrameRate(_ fps: Int) {
        guard let window = NSApplication.shared.windows.first else { return }
        for subview in window.contentView?.subviews ?? [] {
            if let skView = subview as? SKView {
                skView.preferredFramesPerSecond = fps
                skView.isPaused = false
            }
        }
    }

    private func handleOcclusionChange(window: NSWindow) {
        let isVisible = window.occlusionState.contains(.visible)
        for subview in window.contentView?.subviews ?? [] {
            if let skView = subview as? SKView {
                skView.isPaused = !isVisible
            }
        }
    }
}
