//
//  FNConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// `FNConnectionBytes` for input and output bytes
public struct FNConnectionBytes: FNConnectionBytesProtocol {
    public var input: Int?
    public var output: Int?
}

/// `FNConnectionState` state handler
@frozen
public enum FNConnectionState {
    case ready
    case cancelled
    case failed(Error?)
}
