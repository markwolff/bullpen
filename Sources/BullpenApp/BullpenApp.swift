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
                .onChange(of: monitorService.agents) { _, newAgents in
                    appDelegate.updateBadge(agents: newAgents)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1024, height: 768)
    }
}

/// App delegate that configures the floating borderless window, manages
/// frame rate tiering, menu bar status item, window position persistence,
/// and the compact menu bar panel display mode.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    /// The menu bar status item (7.1)
    private var statusItem: NSStatusItem!

    /// Reference to the main window for toggle/persistence
    private weak var window: NSWindow?

    /// The compact always-on-top panel for menu bar display mode
    private var popoverPanel: NSPanel?

    /// The current display mode (window or menu bar panel)
    private var displayMode: DisplayMode = DisplayModeStore.load()

    /// Reference to the monitor service for badge updates (set from BullpenApp).
    /// When set, retries panel creation if the app launched in menu bar panel mode
    /// before SwiftUI had a chance to set this reference.
    weak var monitorService: AgentMonitorService? {
        didSet {
            if displayMode == .menuBarPanel && popoverPanel == nil {
                applyDisplayMode()
            }
        }
    }

    /// Tracks window position for parallax delta calculation
    private var lastWindowOrigin: CGPoint?

    /// Debounce timer for resetting parallax after dragging stops
    private var parallaxResetWorkItem: DispatchWorkItem?

    func applicationWillTerminate(_ notification: Notification) {
        monitorService?.stopMonitoring()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        parallaxResetWorkItem?.cancel()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy based on saved display mode
        let policy: NSApplication.ActivationPolicy = displayMode == .menuBarPanel ? .accessory : .regular
        NSApplication.shared.setActivationPolicy(policy)

        // Set up menu bar status item (7.1)
        setupStatusItem()

        // Set up sleep/wake recovery for file monitoring
        setupSleepWakeHandling()

        // Listen for display mode changes from ESC overlay
        setupDisplayModeListener()

        // Configure window after short delay to let SwiftUI create it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.configureMainWindow()
            self.setupFrameRateTiering()
            self.restoreWindowPosition()
            self.setupWindowPositionPersistence()
            self.applyDisplayMode()
        }
    }

    // MARK: - Display Mode

    /// The window currently being used for display (either the main window or the panel).
    private var activeDisplayWindow: NSWindow? {
        displayMode == .menuBarPanel ? popoverPanel : window
    }

    /// Creates the compact always-on-top panel for menu bar display mode.
    private func createPopoverPanel() {
        guard popoverPanel == nil, let monitorService = monitorService else { return }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(rootView: ContentView(monitorService: monitorService))
        popoverPanel = panel
    }

    /// Positions the panel below the menu bar status item.
    private func positionPanelBelowStatusItem() {
        guard let panel = popoverPanel,
              let buttonFrame = statusItem.button?.window?.frame else { return }
        // Anchor panel's top-right to the status item's bottom-center
        let panelWidth = panel.frame.width
        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panel.frame.height
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Applies the current display mode, showing one view and hiding the other.
    private func applyDisplayMode() {
        switch displayMode {
        case .window:
            popoverPanel?.orderOut(nil)
            pauseScene(in: popoverPanel)
            NSApplication.shared.setActivationPolicy(.regular)
            if let window = self.window {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        case .menuBarPanel:
            window?.orderOut(nil)
            pauseScene(in: window)
            NSApplication.shared.setActivationPolicy(.accessory)
            createPopoverPanel()
            positionPanelBelowStatusItem()
            popoverPanel?.makeKeyAndOrderFront(nil)
        }
    }

    /// Switches to a new display mode, persists the choice, and applies it.
    @objc private func switchDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let newMode = DisplayMode(rawValue: rawValue),
              newMode != displayMode else { return }
        displayMode = newMode
        DisplayModeStore.save(newMode)
        applyDisplayMode()
    }

    // MARK: - Display Mode Listener

    /// Listens for display mode changes posted from the ESC overlay in ContentView.
    private func setupDisplayModeListener() {
        NotificationCenter.default.publisher(for: .displayModeChanged)
            .compactMap { $0.object as? String }
            .compactMap { DisplayMode(rawValue: $0) }
            .sink { [weak self] newMode in
                guard let self, newMode != self.displayMode else { return }
                self.displayMode = newMode
                self.applyDisplayMode()
            }
            .store(in: &cancellables)
    }

    // MARK: - 7.1: NSStatusItem

    /// Creates and configures the menu bar status item.
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "building.2", accessibilityDescription: "Bullpen") {
                button.image = image
            } else {
                // Fallback if the SF Symbol is unavailable
                button.title = "BP"
            }
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: - 7.2: Agent count badge + icon tint

    /// Updates the badge count and icon tint on the status item.
    /// Call this whenever the agent list changes.
    func updateBadge(agents: [Models.AgentInfo]) {
        let activeAgents = agents.filter {
            $0.state != .idle && $0.state != .finished && !$0.isSubagent
        }.count
        let activeSubagents = agents.filter {
            $0.state != .idle && $0.state != .finished && $0.isSubagent
        }.count
        let total = agents.count

        if activeAgents == 0 && activeSubagents == 0 {
            statusItem?.button?.title = total > 0 ? " \(total)" : ""
        } else if activeSubagents > 0 {
            statusItem?.button?.title = " \(activeAgents)+\(activeSubagents)/\(total)"
        } else {
            statusItem?.button?.title = " \(activeAgents)/\(total)"
        }

        // Tint icon green when any agent is active
        let hasActiveAgents = agents.contains {
            $0.state != .idle && $0.state != .finished
        }
        statusItem?.button?.contentTintColor = hasActiveAgents ? .systemGreen : nil
    }

    // MARK: - 7.3: Click to toggle display

    @objc private func statusItemClicked() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }
        toggleDisplay()
    }

    /// Toggles the active display (window or panel) visibility.
    @objc func toggleDisplay() {
        switch displayMode {
        case .window:
            toggleWindow()
        case .menuBarPanel:
            togglePanel()
        }
    }

    /// Toggles the main window visibility.
    private func toggleWindow() {
        guard let window = self.window ?? NSApplication.shared.windows.first else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Toggles the menu bar panel visibility.
    private func togglePanel() {
        createPopoverPanel()
        guard let panel = popoverPanel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            pauseScene(in: panel)
        } else {
            positionPanelBelowStatusItem()
            panel.makeKeyAndOrderFront(nil)
            resumeScene(in: panel)
        }
    }

    // MARK: - 7.4: Right-click context menu

    /// Shows a context menu from the status item on right-click.
    func showContextMenu() {
        let menu = NSMenu()

        // Show/Hide toggle
        let activeWindow = activeDisplayWindow
        let isVisible = activeWindow?.isVisible ?? false
        let showHide = NSMenuItem(
            title: isVisible ? "Hide Office" : "Show Office",
            action: #selector(toggleDisplay),
            keyEquivalent: ""
        )
        showHide.target = self
        menu.addItem(showHide)
        menu.addItem(.separator())

        // Display Mode submenu
        let displayModeMenu = NSMenu()
        for mode in DisplayMode.allCases {
            let item = NSMenuItem(
                title: mode.title,
                action: #selector(switchDisplayMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (mode == displayMode) ? .on : .off
            displayModeMenu.addItem(item)
        }
        let displayModeItem = NSMenuItem(title: "Display Mode", action: nil, keyEquivalent: "")
        displayModeItem.submenu = displayModeMenu
        menu.addItem(displayModeItem)

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

    // MARK: - Sleep/Wake Recovery

    /// Registers for system wake notifications to restart file monitoring.
    /// GCD DispatchSource VNODE watchers and Foundation timers can silently
    /// stop working after macOS sleep — this ensures recovery.
    private func setupSleepWakeHandling() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                // Brief delay for hardware and file systems to stabilize
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.monitorService?.handleSystemWake()
                }
            }
            .store(in: &cancellables)
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

    /// Observes window move notifications to auto-save position and apply parallax.
    private func setupWindowPositionPersistence() {
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)
            .sink { [weak self] _ in
                self?.saveWindowPosition()
                self?.handleParallax()
            }
            .store(in: &cancellables)
    }

    /// Computes window drag delta and applies parallax to the office scene background.
    private func handleParallax() {
        guard let window = self.window else { return }
        let origin = window.frame.origin

        guard let last = lastWindowOrigin else {
            lastWindowOrigin = origin
            return
        }

        let dx = origin.x - last.x
        let dy = origin.y - last.y
        lastWindowOrigin = origin

        guard let contentView = window.contentView,
              let skView = findSKView(in: contentView),
              let scene = skView.scene as? OfficeScene else { return }

        scene.applyParallax(dx: dx, dy: dy)

        // Debounce reset: after 0.3s of no movement, animate back to origin
        parallaxResetWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak scene] in
            scene?.resetParallax()
        }
        parallaxResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
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

    // MARK: - Frame Rate Tiering

    /// Sets up frame rate tiering — task 4.13
    /// - Active: 30 FPS
    /// - Inactive: 10 FPS
    /// - Occluded: pause scene
    private func setupFrameRateTiering() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self, let win = self.activeDisplayWindow else { return }
                self.setFrameRate(30, in: win)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                guard let self, let win = self.activeDisplayWindow else { return }
                self.setFrameRate(10, in: win)
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

    private func setFrameRate(_ fps: Int, in window: NSWindow) {
        guard let contentView = window.contentView,
              let skView = findSKView(in: contentView) else { return }
        skView.preferredFramesPerSecond = fps
        skView.ignoresSiblingOrder = true
        skView.isPaused = false
    }

    private func handleOcclusionChange(window: NSWindow) {
        let isVisible = window.occlusionState.contains(.visible)
        guard let contentView = window.contentView,
              let skView = findSKView(in: contentView) else { return }
        skView.isPaused = !isVisible
    }

    /// Pauses the SpriteKit scene in a given window.
    private func pauseScene(in window: NSWindow?) {
        guard let contentView = window?.contentView,
              let skView = findSKView(in: contentView) else { return }
        skView.isPaused = true
    }

    /// Resumes the SpriteKit scene in a given window at 30 FPS.
    private func resumeScene(in window: NSWindow?) {
        guard let window else { return }
        setFrameRate(30, in: window)
    }
}
