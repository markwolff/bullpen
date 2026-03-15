import SwiftUI
import SpriteKit
import SpriteWorld
import Services
import Models
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
                    appDelegate.monitorService = monitorService
                }
                .onDisappear {
                    monitorService.stopMonitoring()
                }
                .onChange(of: monitorService.agents) { _, newAgents in
                    appDelegate.updateBadge(agents: newAgents)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1024, height: 768)
    }
}

/// App delegate that configures the floating borderless window, manages
/// frame rate tiering, menu bar status item, and window position persistence.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    /// The menu bar status item (7.1)
    private var statusItem: NSStatusItem!

    /// Reference to the main window for toggle/persistence
    private var window: NSWindow?

    /// Reference to the monitor service for badge updates (set from BullpenApp)
    var monitorService: AgentMonitorService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (no dock icon) — task 4.12
        NSApplication.shared.setActivationPolicy(.accessory)

        // Set up menu bar status item (7.1)
        setupStatusItem()

        // Configure window after short delay to let SwiftUI create it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.configureMainWindow()
            self.setupFrameRateTiering()
            self.restoreWindowPosition()
            self.setupWindowPositionPersistence()
        }
    }

    // MARK: - 7.1: NSStatusItem

    /// Creates and configures the menu bar status item.
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "building.2", accessibilityDescription: "Bullpen")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]
            )
        }
    }

    // MARK: - 7.2: Agent count badge

    /// Updates the badge count on the status item.
    /// Call this whenever the agent list changes.
    func updateBadge(agents: [Models.AgentInfo]) {
        let activeCount = agents.filter {
            $0.state != .idle && $0.state != .finished
        }.count
        statusItem?.button?.title = activeCount > 0 ? " \(activeCount)" : ""
    }

    // MARK: - 7.3: Click to toggle window

    @objc private func statusItemClicked() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }
        toggleWindow()
    }

    /// Toggles the main window visibility.
    @objc func toggleWindow() {
        guard let window = self.window ?? NSApplication.shared.windows.first else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - 7.4: Right-click context menu

    /// Shows a context menu from the status item on right-click.
    func showContextMenu() {
        let menu = NSMenu()
        let isVisible = window?.isVisible ?? false
        let showHide = NSMenuItem(
            title: isVisible ? "Hide Office" : "Show Office",
            action: #selector(toggleWindow),
            keyEquivalent: ""
        )
        showHide.target = self
        menu.addItem(showHide)
        menu.addItem(.separator())
        let prefs = NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ",")
        menu.addItem(prefs)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Bullpen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Defer clearing so the menu has time to display
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil  // Reset so left-click still works
        }
    }

    // MARK: - 7.12: Window position persistence

    /// Saves the window's current position to UserDefaults.
    func saveWindowPosition() {
        guard let window = self.window else { return }
        let frame = window.frame
        UserDefaults.standard.set(frame.origin.x, forKey: "windowPosX")
        UserDefaults.standard.set(frame.origin.y, forKey: "windowPosY")
    }

    /// Restores the window position from UserDefaults.
    func restoreWindowPosition() {
        let x = UserDefaults.standard.double(forKey: "windowPosX")
        let y = UserDefaults.standard.double(forKey: "windowPosY")
        if x != 0 || y != 0 {
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    /// Observes window move notifications to auto-save position.
    private func setupWindowPositionPersistence() {
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)
            .sink { [weak self] _ in
                self?.saveWindowPosition()
            }
            .store(in: &cancellables)
    }

    /// Configures the main window as a floating, borderless, transparent overlay.
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        self.window = window
        window.level = .normal
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

    private func findSKView(in view: NSView) -> SKView? {
        if let skView = view as? SKView { return skView }
        for subview in view.subviews {
            if let found = findSKView(in: subview) { return found }
        }
        return nil
    }

    private func setFrameRate(_ fps: Int) {
        guard let window = self.window ?? NSApplication.shared.windows.first,
              let contentView = window.contentView,
              let skView = findSKView(in: contentView) else { return }
        skView.preferredFramesPerSecond = fps
        skView.isPaused = false
    }

    private func handleOcclusionChange(window: NSWindow) {
        let isVisible = window.occlusionState.contains(.visible)
        guard let contentView = window.contentView,
              let skView = findSKView(in: contentView) else { return }
        skView.isPaused = !isVisible
    }
}
