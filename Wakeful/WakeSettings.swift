import Foundation

enum DurationMode: String, CaseIterable, Identifiable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case fourHours
    case untilStopped
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .fourHours: return "4 hours"
        case .untilStopped: return "Until stopped"
        case .custom: return "Custom"
        }
    }

    var presetSeconds: Int? {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .untilStopped, .custom: return nil
        }
    }
}

@MainActor
final class WakeSettings: ObservableObject {
    private enum Keys {
        static let durationMode = "durationMode"
        static let customDurationSeconds = "customDurationSeconds"
        static let keepDisplayAwake = "keepDisplayAwake"
    }

    @Published var durationMode: DurationMode {
        didSet { UserDefaults.standard.set(durationMode.rawValue, forKey: Keys.durationMode) }
    }

    @Published var customDurationSeconds: Int {
        didSet { UserDefaults.standard.set(customDurationSeconds, forKey: Keys.customDurationSeconds) }
    }

    @Published var keepDisplayAwake: Bool {
        didSet { UserDefaults.standard.set(keepDisplayAwake, forKey: Keys.keepDisplayAwake) }
    }

    init() {
        let defaults = UserDefaults.standard
        durationMode = DurationMode(rawValue: defaults.string(forKey: Keys.durationMode) ?? "") ?? .oneHour
        customDurationSeconds = defaults.object(forKey: Keys.customDurationSeconds) as? Int ?? 3600
        keepDisplayAwake = defaults.bool(forKey: Keys.keepDisplayAwake)
    }

    var durationSeconds: Int? {
        switch durationMode {
        case .custom:
            return customDurationSeconds > 0 ? customDurationSeconds : nil
        case .untilStopped:
            return nil
        default:
            return durationMode.presetSeconds
        }
    }

    var isCustomDurationValid: Bool {
        durationMode != .custom || customDurationSeconds >= 60
    }

    var customHours: Int {
        get { customDurationSeconds / 3600 }
        set { customDurationSeconds = max(60, newValue * 3600 + customMinutes * 60) }
    }

    var customMinutes: Int {
        get { (customDurationSeconds % 3600) / 60 }
        set {
            let total = customHours * 3600 + newValue * 60
            customDurationSeconds = max(60, total)
        }
    }

    var durationDescription: String {
        switch durationMode {
        case .custom:
            return formattedDuration(customDurationSeconds)
        case .untilStopped:
            return DurationMode.untilStopped.displayName
        default:
            return durationMode.displayName
        }
    }

    func formattedDuration(_ seconds: Int) -> String {
        Self.formattedDuration(seconds)
    }

    static func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}
