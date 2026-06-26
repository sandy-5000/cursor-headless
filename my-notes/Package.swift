// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "my-notes",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "my-notes",
            path: "Sources/my-notes"
        ),
        .testTarget(
            name: "my-notesTests",
            dependencies: ["my-notes"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
