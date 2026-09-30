// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Telesm",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Telesm", targets: ["Telesm"])
    ],
    targets: [
        .executableTarget(
            name: "Telesm",
            path: "Sources/Telesm"
        )
    ],
    swiftLanguageModes: [.v5]
)
