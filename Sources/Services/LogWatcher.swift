import Foundation

/// Watches a file or directory for changes using GCD's DispatchSource.
/// Notifies via a callback whenever the watched path is modified.
public final class LogWatcher: Sendable {
    /// Events we care about when watching log files
    private struct WatchState: Sendable {
        let source: DispatchSourceFileSystemObject
        let fileDescriptor: Int32
    }

    private let watchedPath: String
    private let onChange: @Sendable () -> Void
    private let queue: DispatchQueue

    // nonisolated(unsafe) because DispatchSource manages its own thread safety
    private nonisolated(unsafe) var watchState: WatchState?

    /// Pending debounce work item — cancelled and replaced on each rapid-fire event
    private nonisolated(unsafe) var debounceWorkItem: DispatchWorkItem?

    /// Debounce interval for rapid file writes (100ms)
    private let debounceInterval: TimeInterval = 0.1

    /// Creates a new LogWatcher.
    /// - Parameters:
    ///   - path: The file or directory path to watch
    ///   - onChange: Callback fired when the watched path changes
    public init(path: String, onChange: @escaping @Sendable () -> Void) {
        self.watchedPath = path
        self.onChange = onChange
        self.queue = DispatchQueue(label: "com.bullpen.logwatcher.\(UUID().uuidString)")
    }

    /// Starts watching the file for changes.
    public func startWatching() {
        stopWatching()

        let fd = open(watchedPath, O_EVTONLY)
        guard fd >= 0 else {
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self, onChange] in
            // Debounce: cancel any pending work item and schedule a new one.
            // During rapid log writes, this coalesces into a single callback.
            self?.debounceWorkItem?.cancel()
            let item = DispatchWorkItem { onChange() }
            self?.debounceWorkItem = item
            self?.queue.asyncAfter(deadline: .now() + (self?.debounceInterval ?? 0.1), execute: item)
        }

        source.setCancelHandler {
            close(fd)
        }

        self.watchState = WatchState(source: source, fileDescriptor: fd)
        source.resume()
    }

    /// Manually triggers the onChange callback.
    /// Used after system wake to force processing of any log entries
    /// written while the system was asleep and missed by the VNODE source.
    public func triggerCheck() {
        queue.async { [onChange] in
            onChange()
        }
    }

    /// Stops watching the file.
    public func stopWatching() {
        if let state = watchState {
            state.source.cancel()
            watchState = nil
        }
    }

    deinit {
        watchState?.source.cancel()
    }
}
