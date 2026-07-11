import Foundation

struct TrashedApp {
    let name: String
    let bundleIdentifier: String
    let path: URL
}

protocol TrashMonitorDelegate: AnyObject {
    func trashMonitor(_ monitor: TrashMonitor, detected app: TrashedApp)
}

final class TrashMonitor {
    weak var delegate: TrashMonitorDelegate?

    private var stream: FSEventStreamRef?
    private let trashURL: URL
    // Serial queue the FSEvents callback runs on; also guards notifiedPaths
    private let queue = DispatchQueue(label: "com.apptrap.TrashMonitor")
    // Paths of app bundles already reported to the delegate
    private var notifiedPaths: Set<String> = []

    init() {
        trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
    }

    func start() {
        // Seed notifiedPaths with apps already in trash at launch so we don't alert on them
        notifiedPaths = Set(appsCurrentlyInTrash().map { $0.path.path })

        var ctx = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        ctx.info = Unmanaged.passUnretained(self).toOpaque()

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer
        )

        let cb: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<TrashMonitor>.fromOpaque(info).takeUnretainedValue().handleChange()
        }

        guard let s = FSEventStreamCreate(nil, cb, &ctx, [trashURL.path] as CFArray,
                                          FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                          1.5, flags) else { return }

        FSEventStreamSetDispatchQueue(s, queue)
        FSEventStreamStart(s)
        stream = s
    }

    func stop() {
        guard let s = stream else { return }
        FSEventStreamStop(s)
        FSEventStreamInvalidate(s)
        FSEventStreamRelease(s)
        stream = nil
    }

    private func handleChange() {
        let current = appsCurrentlyInTrash()
        let currentPaths = Set(current.map { $0.path.path })
        let newPaths = currentPaths.subtracting(notifiedPaths)
        notifiedPaths = currentPaths

        for app in current where newPaths.contains(app.path.path) {
            delegate?.trashMonitor(self, detected: app)
        }
    }

    private func appsCurrentlyInTrash() -> [TrashedApp] {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: trashURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ) else { return [] }

        return entries
            .filter { $0.pathExtension.lowercased() == "app" }
            .compactMap(parseBundleInfo(at:))
    }

    private func parseBundleInfo(at url: URL) -> TrashedApp? {
        let infoPlist = url.appendingPathComponent("Contents/Info.plist")
        guard let dict = NSDictionary(contentsOf: infoPlist),
              let bundleId = dict["CFBundleIdentifier"] as? String else { return nil }

        let name = (dict["CFBundleName"] as? String)
                ?? (dict["CFBundleDisplayName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent

        return TrashedApp(name: name, bundleIdentifier: bundleId, path: url)
    }
}
