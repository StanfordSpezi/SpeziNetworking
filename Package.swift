// swift-tools-version:5.9

//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription

#if swift(<6)
let swiftConcurrency: SwiftSetting = .enableExperimentalFeature("StrictConcurrency")
#else
let swiftConcurrency: SwiftSetting = .enableUpcomingFeature("StrictConcurrency")
#endif


let package = Package(
    name: "SpeziNetworking",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
        .macOS(.v13),
        .tvOS(.v16)
    ],
    products: [
        .library(name: "ByteCoding", targets: ["ByteCoding"]),
        .library(name: "XCTByteCoding", targets: ["XCTByteCoding"]),
        .library(name: "SpeziNumerics", targets: ["SpeziNumerics"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0")
    ] + swiftLintPackage(),
    targets: [
        .target(
            name: "ByteCoding",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio")
            ],
            swiftSettings: [
                swiftConcurrency
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "XCTByteCoding",
            dependencies: [
                .target(name: "ByteCoding")
            ],
            swiftSettings: [
                swiftConcurrency
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "SpeziNumerics",
            dependencies: [
                .target(name: "ByteCoding"),
                .product(name: "NIO", package: "swift-nio")
            ],
            swiftSettings: [
                swiftConcurrency
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "ByteCodingTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "XCTByteCoding")
            ],
            swiftSettings: [
                swiftConcurrency
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziNumericsTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "SpeziNumerics"),
                .target(name: "XCTByteCoding")
            ],
            swiftSettings: [
                swiftConcurrency
            ],
            plugins: [] + swiftLintPlugin()
        )
    ]
)


func swiftLintPlugin() -> [Target.PluginUsage] {
    // Fully quit Xcode and open again with `open --env SPEZI_DEVELOPMENT_SWIFTLINT /Applications/Xcode.app`
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
    } else {
        []
    }
}

func swiftLintPackage() -> [PackageDescription.Package.Dependency] {
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.1")]
    } else {
        []
    }
}
