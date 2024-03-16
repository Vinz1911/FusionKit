//
//  FKConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKConnectionBytes` for input and output bytes
public struct FKConnectionBytes: Sendable {
    public internal(set) var input: Int?
    public internal(set) var output: Int?
}

// MARK: - State Types -

/// The `FKConnectionState` state handler
@frozen
public enum FKConnectionState: Sendable {
    case ready
    case cancelled
    case failed(Error?)
}

/// The `FKTransmitter` internal message transmitter
@frozen
internal enum FKTransmitter: Sendable {
    case message(FKConnectionMessage)
    case bytes(FKConnectionBytes)
}
