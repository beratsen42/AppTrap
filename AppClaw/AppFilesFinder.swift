import Foundation

enum AppFilesFinder {
    static func find(bundleIdentifier: String, appName: String) -> [URL] {
        var results: Set<URL> = []
        let fm = FileManager.default

        for dir in searchDirectories() {
            guard let entries = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: []) else { continue }

            for entry in entries where matches(entry, bundleIdentifier: bundleIdentifier, appName: appName) {
                results.insert(entry)
            }
        }

        return results.sorted { $0.path < $1.path }
    }

    // Returns true when the file/folder name relates to the given app
    private static func matches(_ url: URL, bundleIdentifier: String, appName: String) -> Bool {
        let full = url.lastPathComponent
        let stem = url.deletingPathExtension().lastPathComponent

        if stem == bundleIdentifier || stem == appName { return true }
        if full.hasPrefix(bundleIdentifier + ".") || full.hasPrefix(bundleIdentifier + " ") { return true }
        if !appName.isEmpty && (full.hasPrefix(appName + " ") || full.hasPrefix(appName + ".")) { return true }

        // Catch reversed-domain prefixes like "com.example." entries
        let components = bundleIdentifier.components(separatedBy: ".")
        if components.count >= 3 {
            let prefix = components.prefix(3).joined(separator: ".")
            if full.hasPrefix(prefix) { return true }
        }

        return false
    }

    private static func searchDirectories() -> [URL] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let userLib = home.appendingPathComponent("Library")
        let sysLib = URL(fileURLWithPath: "/Library")

        let candidates: [URL] = [
            userLib.appendingPathComponent("Preferences"),
            userLib.appendingPathComponent("Application Support"),
            userLib.appendingPathComponent("Caches"),
            userLib.appendingPathComponent("Containers"),
            userLib.appendingPathComponent("Group Containers"),
            userLib.appendingPathComponent("Logs"),
            sysLib.appendingPathComponent("Preferences"),
            sysLib.appendingPathComponent("Application Support"),
            sysLib.appendingPathComponent("Caches"),
        ]

        return candidates.filter { fm.fileExists(atPath: $0.path) }
    }
}
