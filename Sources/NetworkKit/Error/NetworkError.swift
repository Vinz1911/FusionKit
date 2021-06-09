//
//  NetworkError.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 02.04.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//
import Foundation

/// main class specific errors
public enum NetworkConnectionError: Error {
    case missingHost
    case missingPort
    case connectionTimeout
    
    var description: String {
        switch self {
        case .missingHost: return "missing host"
        case .missingPort: return "missing port"
        case .connectionTimeout: return "connection timeout"
        }
    }
}

/// peer frame speicific errors
public enum NetworkFrameError: Error {
    case parsingFailed
    case emptyBuffer
    case readBufferOverflow
    case writeBufferOverflow
    
    var description: String {
        switch self {
        case .parsingFailed: return "message parsing failed"
        case .emptyBuffer: return "unexpected empty buffer"
        case .readBufferOverflow: return "read buffer overflow"
        case .writeBufferOverflow: return "write buffer overflow"
        }
    }
}
