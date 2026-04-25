import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    enum DefaultsKeys {
        static let hudEnabled = "Spaced.hudEnabled"
        static let hudHoldDuration = "Spaced.hudHoldDuration"
        static let menuBarIconEnabled = "Spaced.menuBarIconEnabled"
        static let launchAtLoginRequested = "Spaced.launchAtLoginRequested"
    }

    static let defaultHUDHoldDuration = 1.4
    static let hudHoldDurationRange = 0.8...3.0

    @Published var hudEnabled: Bool {
        didSet {
            defaults.set(hudEnabled, forKey: DefaultsKeys.hudEnabled)
        }
    }

    @Published var hudHoldDuration: Double {
        didSet {
            let clamped = Self.clampHUDHoldDuration(hudHoldDuration)
            if hudHoldDuration != clamped {
                hudHoldDuration = clamped
            }

            defaults.set(clamped, forKey: DefaultsKeys.hudHoldDuration)
        }
    }

    @Published var menuBarIconEnabled: Bool {
        didSet {
            defaults.set(menuBarIconEnabled, forKey: DefaultsKeys.menuBarIconEnabled)
        }
    }

    @Published var launchAtLoginRequested: Bool {
        didSet {
            defaults.set(launchAtLoginRequested, forKey: DefaultsKeys.launchAtLoginRequested)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        hudEnabled = defaults.object(forKey: DefaultsKeys.hudEnabled) as? Bool ?? true
        hudHoldDuration = Self.clampHUDHoldDuration(
            defaults.object(forKey: DefaultsKeys.hudHoldDuration) as? Double ?? Self.defaultHUDHoldDuration
        )
        menuBarIconEnabled = defaults.object(forKey: DefaultsKeys.menuBarIconEnabled) as? Bool ?? true
        launchAtLoginRequested = defaults.object(forKey: DefaultsKeys.launchAtLoginRequested) as? Bool ?? false
    }

    static func clampHUDHoldDuration(_ value: Double) -> Double {
        min(max(value, hudHoldDurationRange.lowerBound), hudHoldDurationRange.upperBound)
    }
}
