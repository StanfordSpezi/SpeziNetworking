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
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .macOS(.v14),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "ByteCoding", targets: ["ByteCoding"]),
        .library(name: "XCTByteCoding", targets: ["XCTByteCoding"]),
        .library(name: "SpeziNumerics", targets: ["SpeziNumerics"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0"),
        .package(url: "git@github.com:StanfordSpezi/SpeziFoundation.git", from: "1.0.4")
    ],
    targets: [
        .target(
            name: "ByteCoding",
            dependencies: [
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
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
