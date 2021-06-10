//
//  NetworkResult.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 09.06.21.
//

import Foundation

/// result type for input and output bytes
public struct NetworkBytes {
    public var input: Int?
    public var output: Int?
}

/// network connection result type
public enum NetworkConnectionResult {
    case ready
    case cancelled
    case failed(Error?)
    case message(NetworkMessage)
    case bytes(NetworkBytes)
}
