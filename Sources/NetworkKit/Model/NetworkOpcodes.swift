//
//  Opcodes.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 02.04.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//
import Foundation

/// opcodes for framing
internal enum NetworkOpcodes: UInt8 {
    case none = 0x0
    case text = 0x1
    case binary = 0x2
}
