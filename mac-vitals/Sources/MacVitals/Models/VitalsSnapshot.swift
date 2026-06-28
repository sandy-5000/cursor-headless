import Foundation

/// A single, self-contained read of all the metrics we care about.
///
/// This is the unit that the background agent writes and the UI reads. It is
/// `Codable` so the exact same type can be shared with a WidgetKit extension
/// through an App Group cache (see README architecture) without any changes.
struct VitalsSnapshot: Codable, Sendable, Equatable {
    var memory: MemoryInfo
    var storage: StorageInfo
    var battery: BatteryInfo
    var capturedAt: Date

    /// Empty snapshot used before the first real read completes.
    static let placeholder = VitalsSnapshot(
        memory: MemoryInfo(usedBytes: 0, totalBytes: 0),
        storage: StorageInfo(usedBytes: 0, totalBytes: 0),
        battery: BatteryInfo(hasBattery: false, percentage: nil, state: .acPower),
        capturedAt: .distantPast
    )
}

struct MemoryInfo: Codable, Sendable, Equatable {
    var usedBytes: UInt64
    var totalBytes: UInt64

    var fraction: Double {
        totalBytes == 0 ? 0 : min(1, Double(usedBytes) / Double(totalBytes))
    }
    var percent: Int { Int((fraction * 100).rounded()) }
}

struct StorageInfo: Codable, Sendable, Equatable {
    var usedBytes: UInt64
    var totalBytes: UInt64

    var fraction: Double {
        totalBytes == 0 ? 0 : min(1, Double(usedBytes) / Double(totalBytes))
    }
    var percent: Int { Int((fraction * 100).rounded()) }
}

enum BatteryState: String, Codable, Sendable {
    case charging          // on AC and actively charging
    case pluggedNotCharging // on AC, full / not charging
    case onBattery         // running off the battery
    case acPower           // desktop Mac with no battery

    var label: String {
        switch self {
        case .charging: return "Charging"
        case .pluggedNotCharging: return "On power"
        case .onBattery: return "On battery"
        case .acPower: return "On power"
        }
    }
}

struct BatteryInfo: Codable, Sendable, Equatable {
    /// `false` on desktop Macs (no internal battery).
    var hasBattery: Bool
    /// 0–100, or `nil` when there is no battery.
    var percentage: Int?
    var state: BatteryState
}
