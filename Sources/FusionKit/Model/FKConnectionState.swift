//
//  FKConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKConnectionBytes` for input and output bytes
public struct FKConnectionBytes: FKConnectionBytesProtocol, Sendable {
    public var input: Int?
    public var output: Int?
}

/// The `FKConnectionState`
@frozen
public enum FKConnectionState: Sendable {
    case running
    case suspended
    case completed
}

/// The `FKConnectionResult` message result
@frozen
public enum FKConnectionResult: Sendable {
    case message(FKConnectionMessage)
    case bytes(FKConnectionBytes)
}

/// The `FKConnectionIntercom` internal result transmission
@frozen
internal enum FKConnectionIntercom: Sendable {
    case ready
    case cancelled
    case failed(Error?)
    case result(FKConnectionResult)
}
