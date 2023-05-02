//
//  FNConnectionError.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// network connection specific errors
public enum FNConnectionError: Error {
    case missingHost
    case missingPort
    case connectionTimeout
    case connectionUnsatisfied
    
    public var description: String {
        switch self {
        case .missingHost: return "missing host"
        case .missingPort: return "missing port"
        case .connectionTimeout: return "connection timeout"
        case .connectionUnsatisfied: return "connection path is not satisfied"
        }
    }
}

/// network frame specific errors
public enum FNConnectionFrameError: Error {
    case hashMismatch
    case parsingFailed
    case readBufferOverflow
    case writeBufferOverflow
    
    public var description: String {
        switch self {
        case .hashMismatch: return "message hash does not match"
        case .parsingFailed: return "message parsing failed"
        case .readBufferOverflow: return "read buffer overflow"
        case .writeBufferOverflow: return "write buffer overflow"
        }
    }
}
