import Foundation
import IOKit.ps

/// Listens for power-source changes via IOKit and fires `onChange` — no polling.
///
/// `IOPSNotificationCreateRunLoopSource` gives us a run-loop source that wakes
/// only on real events: plug/unplug, charge-level crossings, charging-state
/// changes. While nothing happens the thread is blocked in the run loop at ~0% CPU.
final class BatteryMonitor {
    /// Called on the main run loop whenever a power-source event arrives.
    var onChange: (@Sendable () -> Void)?

    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard runLoopSource == nil else { return }

        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { rawContext in
            guard let rawContext else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(rawContext).takeUnretainedValue()
            monitor.onChange?()
        }

        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?
            .takeRetainedValue()
        else { return }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
    }

    deinit { stop() }
}
