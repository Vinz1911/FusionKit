//
//  FKOpcodes.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// Opcodes for framing
internal enum FKOpcodes: UInt8, Sendable {
    case none = 0x0
    case text = 0x1
    case binary = 0x2
    case ping = 0x3
}

/// Protocol byte constants
internal enum FKConstants: Int, Sendable {
    case opcode = 0x1
    case control = 0x5
    case frame = 0xFFFFFFFF
}
