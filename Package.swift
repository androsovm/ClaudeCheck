// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCheck",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeCheck",
            path: "Sources/ClaudeCheck"
        )
    ]
)
