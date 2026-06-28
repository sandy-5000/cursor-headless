import Foundation

/// RAM is hybrid: there is no "memory usage changed by 1%" callback, so we lean
/// on memory-pressure events (free) and add an *optional* slow sampler that runs
/// only while the UI is visible.
final class MemoryMonitor {
    /// Called on the main queue on pressure events or sampler ticks.
    var onChange: (@Sendable () -> Void)?

    private var pressureSource: DispatchSourceMemoryPressure?
    private var sampler: DispatchSourceTimer?

    func start() {
        guard pressureSource == nil else { return }

        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.normal, .warning, .critical],
            queue: .main
        )
        source.setEventHandler { [weak self] in self?.onChange?() }
        source.resume()
        pressureSource = source
    }

    /// Keeps the displayed RAM number smooth while the popover is open. Disabled
    /// when hidden so idle CPU stays at zero. Interval is >= 30s per the budget.
    func startSampling(interval: TimeInterval = 30) {
        stopSampling()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .seconds(5))
        timer.setEventHandler { [weak self] in self?.onChange?() }
        timer.resume()
        sampler = timer
    }

    func stopSampling() {
        sampler?.cancel()
        sampler = nil
    }

    func stop() {
        pressureSource?.cancel()
        pressureSource = nil
        stopSampling()
    }

    deinit { stop() }
}
