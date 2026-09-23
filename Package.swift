// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceGlowSwift",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [.library(name: "VoiceGlowSwift", targets: ["VoiceGlowSwift"])],
    targets: [
        .target(name: "VoiceGlowSwift"),
        .testTarget(name: "VoiceGlowSwiftTests", dependencies: ["VoiceGlowSwift"]),
    ]
)
