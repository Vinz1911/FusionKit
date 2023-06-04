//
//  FKConnectionError.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKConnection` specific errors
public enum FKConnectionError: Error {
    case missingHost
    case missingPort
    case connectionTimeout
    case connectionUnsatisfied
    case hashMismatch
    case parsingFailed
    case readBufferOverflow
    case writeBufferOverflow
    
    public var description: String {
        switch self {
        case .missingHost: return "missing host"
        case .missingPort: return "missing port"
        case .connectionTimeout: return "connection timeout"
        case .connectionUnsatisfied: return "connection path is not satisfied"
        case .hashMismatch: return "message hash does not match"
        case .parsingFailed: return "message parsing failed"
        case .readBufferOverflow: return "read buffer overflow"
        case .writeBufferOverflow: return "write buffer overflow" }
    }
}
