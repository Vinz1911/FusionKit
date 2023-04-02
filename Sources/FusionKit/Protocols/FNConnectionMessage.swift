//
//  FNConnectionMessage.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// protocol for message compliance
public protocol FNConnectionMessage {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// conformance to protocol 'FNConnectionMessage'
extension UInt16: FNConnectionMessage {
    public var opcode: UInt8 { FNConnectionOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// conformance to protocol 'FNConnectionMessage'
extension String: FNConnectionMessage {
    public var opcode: UInt8 { FNConnectionOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// conformance to protocol 'FNConnectionMessage'
extension Data: FNConnectionMessage {
    public var opcode: UInt8 { FNConnectionOpcodes.binary.rawValue }
    public var raw: Data { self }
}
