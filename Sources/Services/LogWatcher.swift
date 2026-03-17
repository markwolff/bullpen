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
            // TODO: Log error — could not open file for watching
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [onChange] in
            onChange()
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
