// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Telecursor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Telecursor",
            path: "Telecursor"
        )
    ]
)
