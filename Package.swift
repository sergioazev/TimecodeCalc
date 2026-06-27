// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimecodeCalc",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TimecodeCalc",
            path: "Sources/TimecodeCalc"
        )
    ]
)
