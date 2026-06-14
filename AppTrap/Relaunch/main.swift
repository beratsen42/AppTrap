//
//  main.swift
//  Relaunch
//

import AppKit

guard CommandLine.arguments.count > 1,
      let parentPID = Int32(CommandLine.arguments[1]),
      let app = NSRunningApplication(processIdentifier: parentPID),
      let bundleURL = app.bundleURL
else { exit(1) }

// Wait for the parent process to terminate, then relaunch it.
let task = Task {
    await waitForTermination(of: app)

    let config = NSWorkspace.OpenConfiguration()
    config.addsToRecentItems = false
    config.activates = false

    try await NSWorkspace.shared.openApplication(at: bundleURL, configuration: config)
}

app.terminate()
RunLoop.main.run()

// MARK: - Helpers

func waitForTermination(of app: NSRunningApplication) async {
    await withCheckedContinuation { continuation in
        let observer = TerminationObserver(app: app) {
            continuation.resume()
        }
        // Keep observer alive until the continuation resumes.
        withExtendedLifetime(observer) {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 30))
        }
    }
}

final class TerminationObserver: NSObject, @unchecked Sendable {
    private let app: NSRunningApplication
    private let onTerminated: () -> Void
    private var observing = false

    init(app: NSRunningApplication, onTerminated: @escaping () -> Void) {
        self.app = app
        self.onTerminated = onTerminated
        super.init()
        app.addObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated),
                        options: .new, context: nil)
        observing = true
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(NSRunningApplication.isTerminated),
              app.isTerminated
        else { return }
        removeObserverIfNeeded()
        onTerminated()
    }

    private func removeObserverIfNeeded() {
        if observing {
            app.removeObserver(self, forKeyPath: #keyPath(NSRunningApplication.isTerminated))
            observing = false
        }
    }

    deinit { removeObserverIfNeeded() }
}
