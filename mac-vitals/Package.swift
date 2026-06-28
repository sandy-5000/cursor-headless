// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacVitals",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // The background agent + menu-bar UI. Owns all the event listeners and
        // renders the live vitals. Built into a real `.app` bundle by build-app.sh.
        .executableTarget(
            name: "MacVitals"
        ),
        .testTarget(
            name: "MacVitalsTests",
            dependencies: ["MacVitals"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
