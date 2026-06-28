import Foundation
import IOKit.ps

/// One-shot, side-effect-free reads of each metric.
///
/// Per the README design principle ("events first, polling last"), nothing here
/// loops or schedules. The monitors decide *when* to call these; this type only
/// answers *what* the current values are, as cheaply as possible.
enum MetricsReader {

    static func snapshot(storageURL: URL = URL(fileURLWithPath: "/")) -> VitalsSnapshot {
        VitalsSnapshot(
            memory: readMemory(),
            storage: readStorage(for: storageURL),
            battery: readBattery(),
            capturedAt: Date()
        )
    }

    // MARK: - RAM (Mach host_statistics64)

    static func readMemory() -> MemoryInfo {
        let total = ProcessInfo.processInfo.physicalMemory

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryInfo(usedBytes: 0, totalBytes: total)
        }

        let pageSize = UInt64(sysconf(_SC_PAGESIZE))
        // Roughly mirrors Activity Monitor's "Memory Used": app (active) + wired +
        // compressed. Cached/purgeable pages are intentionally excluded.
        let active = UInt64(stats.active_count)
        let wired = UInt64(stats.wire_count)
        let compressed = UInt64(stats.compressor_page_count)
        let used = (active + wired + compressed) * pageSize

        return MemoryInfo(usedBytes: min(used, total), totalBytes: total)
    }

    // MARK: - Storage (URLResourceValues)

    static func readStorage(for url: URL) -> StorageInfo {
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]

        guard let values = try? url.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity, total > 0
        else {
            return StorageInfo(usedBytes: 0, totalBytes: 0)
        }

        let available = values.volumeAvailableCapacityForImportantUsage ?? 0
        let used = max(0, Int64(total) - available)
        return StorageInfo(usedBytes: UInt64(used), totalBytes: UInt64(total))
    }

    // MARK: - Battery (IOKit power sources)

    static func readBattery() -> BatteryInfo {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(blob, first)?.takeUnretainedValue() as? [String: Any]
        else {
            // No power source entry → desktop Mac running on wall power.
            return BatteryInfo(hasBattery: false, percentage: nil, state: .acPower)
        }

        let current = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let max = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
        let psState = desc[kIOPSPowerSourceStateKey as String] as? String

        let percent = max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : 0

        let state: BatteryState
        if isCharging {
            state = .charging
        } else if psState == (kIOPSACPowerValue as String) {
            state = .pluggedNotCharging
        } else {
            state = .onBattery
        }

        return BatteryInfo(hasBattery: true, percentage: percent, state: state)
    }
}
