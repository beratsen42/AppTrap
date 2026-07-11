import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var trashMonitor: TrashMonitor?
    private var statusItem: NSStatusItem?
    private var activeControllers: [CleanupWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        registerLoginItemIfNeeded()
        checkPermissionsAndStartMonitoring()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let image = NSImage(named: "MenuBarIcon")
                ?? NSImage(systemSymbolName: "trash.circle.fill", accessibilityDescription: "AppClaw")
            image?.isTemplate = true
            button.image = image
        }
        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let header = NSMenuItem(title: "AppClaw", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = LoginItemManager.shared.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit AppClaw", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    @objc private func toggleLoginItem() {
        LoginItemManager.shared.toggle()
        statusItem?.menu = buildMenu()
    }

    // MARK: - Login Item

    private func registerLoginItemIfNeeded() {
        guard !LoginItemManager.shared.hasBeenConfigured else { return }
        LoginItemManager.shared.enable()
    }

    // MARK: - Permissions & Monitoring

    private func checkPermissionsAndStartMonitoring() {
        let mgr = PermissionsManager()
        if mgr.hasFullDiskAccess() {
            startMonitoring()
        } else {
            mgr.showPermissionsGuide { [weak self] in
                self?.startMonitoring()
            }
        }
    }

    private func startMonitoring() {
        trashMonitor = TrashMonitor()
        trashMonitor?.delegate = self
        trashMonitor?.start()
    }

    // MARK: - Cleanup

    private func presentCleanup(for trashedApp: TrashedApp, files: [URL]) {
        let controller = CleanupWindowController(app: trashedApp, files: files)
        controller.onDismiss = { [weak self, weak controller] in
            self?.activeControllers.removeAll { $0 === controller }
        }
        activeControllers.append(controller)
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
    }
}

// MARK: - TrashMonitorDelegate

extension AppDelegate: TrashMonitorDelegate {
    func trashMonitor(_ monitor: TrashMonitor, detected app: TrashedApp) {
        DispatchQueue.global(qos: .userInitiated).async {
            let files = AppFilesFinder.find(bundleIdentifier: app.bundleIdentifier, appName: app.name)
            guard !files.isEmpty else { return }
            DispatchQueue.main.async {
                self.presentCleanup(for: app, files: files)
            }
        }
    }
}
