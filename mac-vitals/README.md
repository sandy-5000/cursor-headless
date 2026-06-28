# Mac Vitals

A native macOS **desktop widget** that shows live **storage**, **battery**, and **RAM** usage — designed to stay idle at ~0% CPU and wake only when the system tells us something changed.

![Status: working POC](https://img.shields.io/badge/status-working%20POC-brightgreen)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)

> **Note:** A working agent is now implemented as a Swift Package. It owns all the
> event listeners (IOKit power, memory pressure, mount/unmount), debounces them into
> one read, and renders live RAM / Storage / Battery in a **floating desktop
> widget** — a borderless, translucent, draggable card pinned to the top-right of
> the screen (no Dock icon, no menu-bar item) at ~0% idle CPU. A true WidgetKit
> extension needs a full Xcode project; this floating panel delivers the same
> always-on-desktop experience meanwhile, and the `VitalsSnapshot` model and
> `MetricsReader` are structured to drop straight into an App Group cache when the
> WidgetKit version is added.

## Build & run

```bash
swift build                 # compile the package
swift run                   # run the agent directly (look in the menu bar)
./build-app.sh --run        # build a proper MacVitals.app (LSUIElement) and launch it
./build-app.sh --install    # build + copy into /Applications
```

> Running tests (`swift test`) needs the full Xcode toolchain — the standalone
> Command Line Tools don't ship the testing frameworks.

---

## What it does

A small WidgetKit widget for the macOS desktop (Notification Center / desktop widgets) displaying:

| Metric | Example display |
|--------|-------------------|
| **Storage** | `512 GB · 68% used` (boot volume) |
| **Battery** | `87% · Charging` or `On power` (desktop Macs) |
| **RAM** | `12.4 / 16 GB · 78%` |

Updates should feel live when something actually changes (plug/unplug power, memory pressure, disk mount) — not from a tight polling loop burning CPU.

---

## Design principle: events first, polling last

macOS does **not** expose a single “RAM usage changed” or “disk bytes changed” notification. The plan is:

1. **Subscribe to every real system event** available for each metric.
2. **Read metrics only when an event fires** (or on widget open / timeline refresh).
3. **Fall back to a slow, adaptive timer** only where no event exists — coalesced and debounced so idle CPU stays near zero.

```
┌─────────────────────────────────────────────────────────┐
│  Background agent (menu-bar helper, LSUIElement)        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ IOKit power │  │ Memory       │  │ NSWorkspace   │  │
│  │ source      │  │ pressure     │  │ mount/unmount │  │
│  │ notifications│ │ DispatchSource│  │ notifications │  │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘  │
│         └────────────────┼──────────────────┘          │
│                          ▼                              │
│              MetricsReader (one-shot read)              │
│                          ▼                              │
│         App Group cache (UserDefaults / file)           │
│                          ▼                              │
│         WidgetCenter.shared.reloadTimelines()           │
└─────────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────┐
│  WidgetKit extension (SwiftUI, read-only UI)            │
│  Reads cached snapshot → renders widget                 │
└─────────────────────────────────────────────────────────┘
```

WidgetKit extensions cannot run IOKit listeners or long-lived loops reliably. A tiny **background agent** (~few MB RAM) owns all listeners and pushes snapshots to the widget via a shared **App Group**.

---

## Event sources per metric

### Battery — true events (IOKit)

| API | Role |
|-----|------|
| `IOPSNotificationCreateRunLoopSource` | Run-loop source; fires on power source changes |
| `kIOPSNotifyPowerSource` | Distributed notification when battery/AC state changes |
| `IOPSCopyPowerSourcesInfo` + `IOPSGetPowerSourceDescription` | Read level, charging state, time remaining |

**Triggers widget refresh when:** plug/unplug AC, charge level crosses thresholds, battery health state changes.

**Desktop Macs (no battery):** show “On power” or hide the battery row — detected via empty power source list.

### RAM — hybrid (pressure events + rare sampling)

| API | Role |
|-----|------|
| `DispatchSource.makeMemoryPressureSource` | Fires on `normal` / `warning` / `critical` memory pressure |
| `host_statistics64(mach_host_self(), HOST_VM_INFO64, …)` | One-shot read: active, wired, compressed, free pages |
| `ProcessInfo.processInfo.physicalMemory` | Total RAM |

There is **no** public “memory usage changed by 1%” callback. Strategy:

- **Primary:** refresh on memory pressure events (zero cost while idle).
- **Secondary:** optional slow timer (e.g. 30–60 s) **only while the widget is visible** on desktop, disabled when not shown — keeps numbers smooth without a 1 s poll loop.
- **Debounce:** coalesce multiple events within ~500 ms into one read + one `reloadTimelines`.

### Storage — hybrid (mount events + rare sampling)

| API | Role |
|-----|------|
| `NSWorkspace.didMountNotification` / `didUnmountNotification` | Volume attach/detach |
| `URLResourceValues.volumeTotalCapacity` / `volumeAvailableCapacity` | Boot volume size (or user-selected volume) |
| `statfs(…)` (fallback) | Low-level capacity for `/` |

Disk usage does not change continuously at the OS level in a way Apple exposes. Strategy:

- **Primary:** refresh on mount/unmount (external drives, disk images).
- **Secondary:** slow background check (e.g. every 5–10 min) or when the user opens Notification Center — storage shifts slowly, so this is acceptable.
- **Optional later:** `FSEvents` on large directories — only if needed; likely overkill for v1.

---

## CPU / power budget

| Rule | Target |
|------|--------|
| Idle state | No timers running; blocked on run loop / dispatch sources only |
| Event handler | Single metric read, write cache, call `reloadTimelines` — sub-ms work |
| Debounce | 500 ms window to avoid storms (e.g. multiple IOKit callbacks) |
| Polling (if any) | ≥ 30 s for RAM, ≥ 5 min for storage; never sub-second |
| Widget UI | Pure SwiftUI read from cache — no work in `TimelineProvider` beyond read + render |

Expected idle CPU: **~0%** (same class as menu-bar apps that only listen for notifications).

---

## Planned stack

| Layer | Technology |
|-------|------------|
| Widget UI | SwiftUI + WidgetKit |
| Background agent | Swift, `LSUIElement` (no dock icon) |
| IPC / cache | App Group (`group.dev.mac-vitals` or similar) + `Codable` snapshot JSON |
| Metrics | IOKit, Mach `host_statistics64`, Foundation / NSWorkspace |
| Build | Xcode project or Swift Package + widget extension target |
| Min OS | macOS 14 (Sonoma) — matches other apps in this repo |

---

## Widget sizes (planned)

| Size | Content |
|------|---------|
| **Small** | RAM % ring or bar |
| **Medium** | RAM + Storage bars |
| **Large** | RAM + Storage + Battery with labels |

User-configurable: which volume to track (default: boot volume).

---

## Project structure

Implemented today (Swift Package):

```
mac-vitals/
├── README.md
├── Package.swift
├── build-app.sh                  # builds MacVitals.app (LSUIElement bundle)
├── Sources/MacVitals/
│   ├── MacVitalsApp.swift        # @main App (hidden Settings scene)
│   ├── App/
│   │   ├── AppDelegate.swift     # .accessory policy + builds the widget panel
│   │   └── WidgetPanel.swift     # borderless, draggable, all-Spaces NSPanel
│   ├── Models/VitalsSnapshot.swift   # Codable snapshot shared-cache-ready
│   ├── Services/
│   │   ├── MetricsReader.swift       # one-shot battery / RAM / storage reads
│   │   ├── BatteryMonitor.swift      # IOKit power-source run-loop source
│   │   ├── MemoryMonitor.swift       # memory-pressure source + adaptive sampler
│   │   ├── StorageMonitor.swift      # NSWorkspace mount/unmount + sampler
│   │   └── MetricsCoordinator.swift  # debounce + publish snapshot
│   └── Views/VitalsMenuView.swift    # SwiftUI widget card (read-only render)
└── Tests/MacVitalsTests/
```

Planned full layout once the WidgetKit extension is added (needs an Xcode project):

```
mac-vitals/
├── README.md
├── MacVitals/                    # Xcode project (TBD)
│   ├── MacVitalsAgent/           # Background listener app
│   │   ├── MacVitalsApp.swift
│   │   ├── Services/
│   │   │   ├── BatteryMonitor.swift      # IOKit notifications
│   │   │   ├── MemoryMonitor.swift       # pressure + host_statistics64
│   │   │   ├── StorageMonitor.swift      # NSWorkspace + URLResourceValues
│   │   │   ├── MetricsCoordinator.swift  # debounce + cache write
│   │   │   └── WidgetReloader.swift      # WidgetCenter.reloadTimelines
│   │   └── Models/
│   │       └── VitalsSnapshot.swift
│   ├── MacVitalsWidget/          # WidgetKit extension
│   │   ├── MacVitalsWidget.swift
│   │   ├── VitalsWidgetView.swift
│   │   └── VitalsTimelineProvider.swift
│   └── Shared/
│       └── VitalsSnapshot.swift  # shared between agent + widget
└── build-app.sh                  # Build .app + embed widget (TBD)
```

---

## Permissions & entitlements (planned)

| Entitlement | Why |
|-------------|-----|
| App Groups | Share snapshot between agent and widget extension |
| (none extra for v1) | Battery/RAM/storage use public APIs — no sandbox escapes needed for read-only stats |

Agent may register as a **Login Item** (optional) so the widget stays fresh after reboot. User opt-in via Settings.

---

## Implementation phases

### Phase 1 — Agent + console
- [x] `MetricsReader` with one-shot battery / RAM / storage reads
- [x] IOKit + memory pressure listeners wired up
- [x] Verify ~0% CPU in Activity Monitor (idle agent measured at 0.0% CPU)

### Phase 2 — UI / Widget
- [x] Floating desktop widget (borderless, translucent, draggable panel)
- [x] RAM + Storage + Battery rows with live bars
- [ ] WidgetKit extension reading App Group cache (needs full Xcode project)
- [ ] `reloadTimelines` on every agent event

### Phase 3 — Polish
- [ ] Login item toggle
- [ ] Volume picker for storage
- [x] Adaptive polling only while the popover is visible
- [x] `build-app.sh` + install instructions

---

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (for WidgetKit extension target) — **or** full Xcode when building the widget; CLI tools alone are not enough for WidgetKit
- Apple Developer signing for App Groups (free Apple ID works for local install)

---

## References

- [IOKit Power Sources (`IOPS.h`)](https://developer.apple.com/documentation/iokit/iops_h)
- [WidgetKit TimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider)
- [Dispatch memory pressure source](https://developer.apple.com/documentation/dispatch/dispatchsource/makememorypressuresource(eventmask:queue:))
- [host_statistics64](https://developer.apple.com/documentation/kernel/1537754-host_statistics64)

---

## License

POC experiment — same terms as the parent repo. Provided as-is for learning and prototyping.
