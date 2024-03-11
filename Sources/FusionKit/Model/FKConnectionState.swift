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

/// The `FKConnectionResult` message result
@frozen
public enum FKConnectionResult {
    case message(FKConnectionMessage)
    case bytes(FKConnectionBytes)
}
