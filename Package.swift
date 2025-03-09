// swift-tools-version:6.0

//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription


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
        .library(name: "SpeziNumerics", targets: ["SpeziNumerics"]),
        .library(name: "XCTByteCoding", targets: ["XCTByteCoding"]),
        .library(name: "ByteCodingTesting", targets: ["ByteCodingTesting"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0"),
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.3")
    ] + swiftLintPackage(),
    targets: [
        .target(
            name: "ByteCoding",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "SpeziNumerics",
            dependencies: [
                .target(name: "ByteCoding"),
                .product(name: "NIOCore", package: "swift-nio")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "ByteCodingTesting",
            dependencies: [
                .target(name: "ByteCoding")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "XCTByteCoding",
            dependencies: [
                .target(name: "ByteCoding")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "ByteCodingTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "ByteCodingTesting")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziNumericsTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "SpeziNumerics"),
                .target(name: "ByteCodingTesting"),
                .product(name: "RealModule", package: "swift-numerics")
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
