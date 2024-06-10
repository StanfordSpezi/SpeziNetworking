//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation


// TODO: docs, hidden?
public struct ByteCodingUserInfoAnchor: RepositoryAnchor {}


public typealias ByteCodingUserInfo = ValueRepository<ByteCodingUserInfoAnchor>

/*
 TODO: custom type?
public struct ByteCodingUserInfo: SharedRepository {
    public typealias Anchor = ByteCodingUserInfoAnchor


    fileprivate init() {}


    public func get<Source>(_ source: Source.Type) -> Source.Value? where Source : SpeziFoundation.KnowledgeSource, ByteCodingUserInfoAnchor == Source.Anchor {
        <#code#>
    }

    public mutating func set<Source>(_ source: Source.Type, value newValue: Source.Value?) where Source : SpeziFoundation.KnowledgeSource, ByteCodingUserInfoAnchor == Source.Anchor {
        <#code#>
    }

    public func collect<Value>(allOf type: Value.Type) -> [Value] {
        <#code#>
    }
}


extension ByteCodingUserInfo {
    @TaskLocal public var userInfo = ByteCodingUserInfo()
}*/
