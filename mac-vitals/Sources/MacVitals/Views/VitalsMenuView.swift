import SwiftUI

/// The desktop widget: a translucent, rounded, draggable card.
struct VitalsWidgetView: View {
    @ObservedObject var coordinator: MetricsCoordinator

    var body: some View {
        VitalsCardView(coordinator: coordinator)
            .frame(width: 248)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .padding(12) // room for the window shadow
    }
}

/// The card contents: read-only render of the latest cached snapshot.
struct VitalsCardView: View {
    @ObservedObject var coordinator: MetricsCoordinator

    var body: some View {
        let snapshot = coordinator.snapshot

        VStack(spacing: 16) {
            header

            HStack(alignment: .top, spacing: 6) {
                GaugeRing(
                    icon: "memorychip",
                    title: "RAM",
                    value: "\(snapshot.memory.percent)%",
                    fraction: snapshot.memory.fraction,
                    caption: "",
                    colors: [.blue, .cyan]
                )

                GaugeRing(
                    icon: "internaldrive",
                    title: "Disk",
                    value: "\(snapshot.storage.percent)%",
                    fraction: snapshot.storage.fraction,
                    caption: "",
                    colors: [.purple, .pink]
                )

                batteryGauge(snapshot.battery)
            }

            storageDetail(snapshot.storage)

            footer(snapshot)
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tint)
            Text("Vitals")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
    }

    private func batteryGauge(_ battery: BatteryInfo) -> some View {
        let pct = battery.percentage
        let fraction = Double(pct ?? 100) / 100
        let colors: [Color]
        if battery.state == .charging {
            colors = [.green, .mint]
        } else if let p = pct, p <= 20 {
            colors = [.red, .orange]
        } else if let p = pct, p <= 40 {
            colors = [.orange, .yellow]
        } else {
            colors = [.green, .teal]
        }

        let icon: String
        switch battery.state {
        case .charging: icon = "bolt.fill"
        case .pluggedNotCharging, .acPower: icon = "powerplug.fill"
        case .onBattery: icon = "battery.75"
        }

        return GaugeRing(
            icon: icon,
            title: "Battery",
            value: pct.map { "\($0)%" } ?? "AC",
            fraction: battery.hasBattery ? fraction : 1,
            caption: battery.state.label,
            colors: colors
        )
    }

    private func storageDetail(_ storage: StorageInfo) -> some View {
        let free = storage.totalBytes >= storage.usedBytes ? storage.totalBytes - storage.usedBytes : 0
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                inlineStat(title: "Total", value: Self.short(storage.totalBytes))
                inlineStat(title: "Used", value: Self.short(storage.usedBytes))
            }

            Spacer(minLength: 10)
            Divider()
                .frame(height: 40)
            Spacer(minLength: 10)

            VStack(spacing: 3) {
                storageLabel("Remaining")
                valueBubble(Self.short(free))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func inlineStat(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            storageLabel(title)
                .frame(width: 32, alignment: .leading)
            valueBubble(value, fontSize: 9)
        }
    }

    private func storageLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 7, weight: .semibold))
            .tracking(0.3)
            .foregroundStyle(.secondary)
    }

    private func valueBubble(_ value: String, fontSize: CGFloat = 11) -> some View {
        Text(value)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(.white.opacity(0.08), in: Capsule())
    }

    private func footer(_ snapshot: VitalsSnapshot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text(updatedText(snapshot))
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private func updatedText(_ snapshot: VitalsSnapshot) -> String {
        guard snapshot.capturedAt != .distantPast else { return "Reading…" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: snapshot.capturedAt)
    }

    static func short(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// A compact circular progress gauge with an icon + value in the middle and a
/// title / caption beneath it.
private struct GaugeRing: View {
    let icon: String
    let title: String
    let value: String
    let fraction: Double
    let caption: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: max(0.001, min(1, fraction)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: colors),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(colors.first ?? .primary)
                    Text(value)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 56, height: 56)
            .animation(.easeInOut(duration: 0.45), value: fraction)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            if !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
