import SwiftUI
import AppKit

/// An invisible `NSViewRepresentable` that intercepts the Escape key
/// in the app's main office window.
///
/// When ESC (keyCode 53) is pressed and the event belongs to the
/// app's main window, the `onEscape` closure fires and the event
/// is consumed (not forwarded to the responder chain).
struct EscapeKeyMonitor: NSViewRepresentable {
    let onEscape: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak coordinator = context.coordinator] event in
            guard event.keyCode == 53 else { return event }
            // Only handle if the event belongs to the app's main window
            guard event.window == NSApplication.shared.mainWindow else { return event }
            coordinator?.onEscape()
            return nil // consume the event
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onEscapeClosure = onEscape
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onEscape: onEscape)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
            coordinator.monitor = nil
        }
    }

    class Coordinator {
        var onEscapeClosure: () -> Void
        var monitor: Any?

        init(onEscape: @escaping () -> Void) {
            self.onEscapeClosure = onEscape
        }

        func onEscape() {
            onEscapeClosure()
        }
    }
}
