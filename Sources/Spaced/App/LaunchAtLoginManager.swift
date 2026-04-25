import Foundation
import ServiceManagement

struct LaunchAtLoginSnapshot: Equatable {
    let isEnabled: Bool
    let isSupported: Bool
    let detail: String
}

@MainActor
final class LaunchAtLoginManager {
    func snapshot() -> LaunchAtLoginSnapshot {
        let service = SMAppService.mainApp

        switch service.status {
        case .enabled:
            return LaunchAtLoginSnapshot(
                isEnabled: true,
                isSupported: true,
                detail: "Spaced opens automatically after login."
            )
        case .notRegistered:
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                isSupported: true,
                detail: "Spaced opens only when launched manually."
            )
        case .requiresApproval:
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                isSupported: true,
                detail: "Approve Spaced in Login Items to finish enabling launch at login."
            )
        case .notFound:
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                isSupported: false,
                detail: "Launch at login is available after Spaced is packaged and signed."
            )
        @unknown default:
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                isSupported: false,
                detail: "Launch at login is unavailable in this environment."
            )
        }
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
