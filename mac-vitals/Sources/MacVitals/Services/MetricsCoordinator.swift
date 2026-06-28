import Foundation
import Combine

/// The brain of the background agent.
///
/// Owns the three event monitors, debounces their callbacks into a single read,
/// and publishes the resulting snapshot for the UI to render. This is the
/// "MetricsCoordinator" box in the README diagram; if a WidgetKit extension were
/// added, the only extra step here would be writing `snapshot` to the App Group
/// cache and calling `WidgetCenter.shared.reloadTimelines(...)`.
@MainActor
final class MetricsCoordinator: ObservableObject {
    @Published private(set) var snapshot: VitalsSnapshot = .placeholder

    private let battery = BatteryMonitor()
    private let memory = MemoryMonitor()
    private let storage = StorageMonitor()

    private var debounce: DispatchWorkItem?
    private var started = false

    /// 500 ms window so a storm of IOKit callbacks collapses into one read.
    private let debounceWindow: TimeInterval = 0.5

    func start() {
        guard !started else { return }
        started = true

        let trigger: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in self?.scheduleRefresh() }
        }
        battery.onChange = trigger
        memory.onChange = trigger
        storage.onChange = trigger

        battery.start()
        memory.start()
        storage.start()

        refresh() // prime the cache immediately
    }

    func stop() {
        battery.stop()
        memory.stop()
        storage.stop()
        debounce?.cancel()
        debounce = nil
        started = false
    }

    /// Call when the UI becomes visible: enable the slow, adaptive samplers that
    /// keep RAM/storage numbers fresh without a tight poll loop.
    func uiBecameVisible() {
        refresh()
        memory.startSampling()
        storage.startSampling()
    }

    /// Call when the UI is hidden: drop back to pure event-driven mode (~0% CPU).
    func uiBecameHidden() {
        memory.stopSampling()
        storage.stopSampling()
    }

    private func scheduleRefresh() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refresh() }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceWindow, execute: work)
    }

    private func refresh() {
        snapshot = MetricsReader.snapshot()
    }
}
