import Foundation
import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()
    private init() {}

    private let configuredKey = "loginItemConfigured"

    var hasBeenConfigured: Bool {
        UserDefaults.standard.bool(forKey: configuredKey)
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func enable() {
        do {
            try SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: configuredKey)
        } catch {
            // Non-fatal: user can always re-enable via the menu
        }
    }

    func disable() {
        try? SMAppService.mainApp.unregister()
    }

    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
            UserDefaults.standard.set(true, forKey: configuredKey)
        }
    }
}
