// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Kubebar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Kubebar", targets: ["Kubebar"]),
        .library(name: "KubebarCore", targets: ["KubebarCore"])
    ],
    targets: [
        .executableTarget(name: "Kubebar", dependencies: ["KubebarCore"], path: "Kubebar"),
        .target(name: "KubebarCore", path: "KubebarCore"),
        .testTarget(name: "KubebarCoreTests", dependencies: ["KubebarCore"], path: "KubebarTests")
    ]
)
