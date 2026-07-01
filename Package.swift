// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimecodeCalc",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure timecode logic — no SwiftUI/AppKit, so it stays testable
        // under Command Line Tools (no full Xcode required).
        .target(
            name: "TimecodeCore",
            path: "Sources/TimecodeCore"
        ),
        // The macOS app.
        .executableTarget(
            name: "TimecodeCalc",
            dependencies: ["TimecodeCore"],
            path: "Sources/TimecodeCalc"
        ),
        // Test runner: `swift run TimecodeCoreTests`. Plain assertions so it
        // runs anywhere; no XCTest/Xcode dependency.
        .executableTarget(
            name: "TimecodeCoreTests",
            dependencies: ["TimecodeCore"],
            path: "Sources/TimecodeCoreTests"
        ),
    ]
)
