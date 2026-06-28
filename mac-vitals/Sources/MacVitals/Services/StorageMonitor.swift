import AppKit

/// Storage barely changes at the OS level, so the primary trigger is volume
/// mount/unmount (external drives, disk images). A slow background check covers
/// the gradual drift of the boot volume.
final class StorageMonitor: @unchecked Sendable {
    /// Called on the main queue on mount/unmount or sampler ticks.
    var onChange: (@Sendable () -> Void)?

    private var observers: [NSObjectProtocol] = []
    private var sampler: DispatchSourceTimer?

    func start() {
        guard observers.isEmpty else { return }

        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didMountNotification,
            NSWorkspace.didUnmountNotification,
            NSWorkspace.didRenameVolumeNotification,
        ]
        for name in names {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.onChange?()
            }
            observers.append(token)
        }
    }

    /// Slow drift check; >= 5 min per the power budget.
    func startSampling(interval: TimeInterval = 600) {
        stopSampling()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .seconds(30))
        timer.setEventHandler { [weak self] in self?.onChange?() }
        timer.resume()
        sampler = timer
    }

    func stopSampling() {
        sampler?.cancel()
        sampler = nil
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
        stopSampling()
    }

    deinit { stop() }
}
