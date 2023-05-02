//
//  FNConnectionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// result type for input and output bytes
public struct FNConnectionBytes {
    public var input: Int?
    public var output: Int?
}

/// network connection state handler
public enum FNConnectionState {
    case ready
    case cancelled
    case failed(Error?)
}
