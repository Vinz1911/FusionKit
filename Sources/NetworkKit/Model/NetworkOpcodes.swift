//
//  NetworkOpcodes.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//
import Foundation

/// opcodes for framing
internal enum NetworkOpcodes: UInt8 {
    case none = 0x0
    case text = 0x1
    case binary = 0x2
}
