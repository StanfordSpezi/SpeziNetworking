//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import NIOCore


private struct PrimitiveByteCodableEndiannessKey: ByteCodingUserInfoKey, DefaultProvidingKnowledgeSource {
    typealias Value = Endianness

    static let defaultValue: Endianness = .little
}


extension ByteCodingUserInfo {
    // TODO: @TaskLocal public var byteCodingUserInfo: ByteCodingUserInfo

    public var defaultEndianness: Endianness {
        get {
            self[PrimitiveByteCodableEndiannessKey.self]
        }
        set {
            self[PrimitiveByteCodableEndiannessKey.self] = newValue
        }
    }
}
