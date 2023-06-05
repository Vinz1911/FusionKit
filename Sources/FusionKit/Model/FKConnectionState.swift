//
//  FKConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKConnectionBytes` for input and output bytes
public struct FKConnectionBytes: FKConnectionBytesProtocol {
    public var input: Int?
    public var output: Int?
}

// MARK: - State Types -

/// The `FKTransmitter` internal message transmitter
@frozen
internal enum FKTransmitter {
    case message(FKConnectionMessage)
    case bytes(FKConnectionBytes)
}

/// The `FKConnectionState` state handler
@frozen
public enum FKConnectionState {
    case ready
    case cancelled
    case failed(Error?)
}
