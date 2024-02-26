//
//  FKConnectionMessage.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import StoreKit

/// Protocol for message compliance
public protocol FKConnectionMessage {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// Conformance to protocol 'FKConnectionMessage'
extension UInt16: FKConnectionMessage {
    public var opcode: UInt8 { FKConnectionOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// Conformance to protocol 'FKConnectionMessage'
extension String: FKConnectionMessage {
    public var opcode: UInt8 { FKConnectionOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// Conformance to protocol 'FKConnectionMessage'
extension Data: FKConnectionMessage {
    public var opcode: UInt8 { FKConnectionOpcodes.binary.rawValue }
    public var raw: Data { self }
}
