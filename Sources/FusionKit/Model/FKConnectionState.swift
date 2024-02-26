//
//  FKConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKConnectionBytes` for input and output bytes
public struct FKConnectionBytes: FKConnectionBytesProtocol, @unchecked Sendable {
    public var input: Int?
    public var output: Int?
}

// MARK: - State Types -

/// The `FKConnectionState` state handler
@frozen
public enum FKConnectionState: @unchecked Sendable {
    case ready
    case cancelled
    case failed(Error?)
}

/// The `FKTransmitter` internal message transmitter
@frozen
internal enum FKTransmitter {
    case message(FKConnectionMessage)
    case bytes(FKConnectionBytes)
}
