//
//  FKState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKBytes` for input and output bytes
public struct FKBytes: Sendable {
    public internal(set) var input: Int?
    public internal(set) var output: Int?
}

// MARK: - State Types -

/// The `FKState` state handler
@frozen
public enum FKState: Sendable {
    case ready
    case cancelled
    case failed(Error?)
}

/// The `FKResult` internal message transmitter
internal enum FKResult: Sendable {
    case message(FKMessage)
    case bytes(FKBytes)
}
