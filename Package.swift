// swift-tools-version:5.9

//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

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
        .library(name: "XCTByteCoding", targets: ["XCTByteCoding"]),
        .library(name: "SpeziNumerics", targets: ["SpeziNumerics"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0")
    ],
    targets: [
        .target(
            name: "ByteCoding",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio")
            ]
        ),
        .target(
            name: "XCTByteCoding",
            dependencies: [
                .target(name: "ByteCoding")
            ]
        ),
        .target(
            name: "SpeziNumerics",
            dependencies: [
                .target(name: "ByteCoding"),
                .product(name: "NIO", package: "swift-nio")
            ]
        ),
        .testTarget(
            name: "ByteCodingTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "XCTByteCoding")
            ]
        ),
        .testTarget(
            name: "SpeziNumericsTests",
            dependencies: [
                .target(name: "ByteCoding"),
                .target(name: "SpeziNumerics"),
                .target(name: "XCTByteCoding")
            ]
        )
    ]
)
