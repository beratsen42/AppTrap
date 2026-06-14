//
//  main.swift
//  Relaunch
//
//  Created by Kumaran Vijayan on 2015-11-11.
//

import AppKit

class Observer: NSObject
{
    private let callback: () -> Void

    init(callback: @escaping () -> Void)
    {
        self.callback = callback
        super.init()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?)
    {
        callback()
    }
}

// main
autoreleasepool {
    guard let parentPID = Int32(CommandLine.arguments[1]),
          let app = NSRunningApplication(processIdentifier: parentPID),
          let bundleURL = app.bundleURL
    else { exit(1) }

    let listener = Observer { CFRunLoopStop(CFRunLoopGetCurrent()) }
    app.addObserver(listener, forKeyPath: "isTerminated", options: [], context: nil)
    app.terminate()
    CFRunLoopRun()
    app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)

    let config = NSWorkspace.OpenConfiguration()
    config.addsToRecentItems = false
    config.activates = false
    NSWorkspace.shared.openApplication(at: bundleURL, configuration: config)
}
