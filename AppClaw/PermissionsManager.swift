import AppKit

final class PermissionsManager {
    // Full Disk Access is required to read protected Library directories.
    // There is no API to request it; we detect it by probing a TCC-protected path
    // and direct the user to System Settings if it's missing.

    func hasFullDiskAccess() -> Bool {
        let tccDB = "/Library/Application Support/com.apple.TCC/TCC.db"
        return FileManager.default.isReadableFile(atPath: tccDB)
    }

    func showPermissionsGuide(completion: @escaping () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = """
            AppClaw needs Full Disk Access to find application support \
            files when apps are moved to the Trash.

            Open System Settings → Privacy & Security → Full Disk Access \
            and enable AppClaw. The change takes effect immediately.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openFDASettings()
        }

        // Start monitoring even without FDA; at minimum user-Library directories
        // are accessible and will produce useful results.
        completion()
    }

    private func openFDASettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
