//
//  NetworkMessage.swift
//  ConnectionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// protocol for message compliance
public protocol NetworkMessage {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// conformance to protocol 'NetworkMessage'
extension UInt16: NetworkMessage {
    public var opcode: UInt8 { NetworkOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// conformance to protocol 'NetworkMessage'
extension String: NetworkMessage {
    public var opcode: UInt8 { NetworkOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// conformance to protocol 'NetworkMessage'
extension Data: NetworkMessage {
    public var opcode: UInt8 { NetworkOpcodes.binary.rawValue }
    public var raw: Data { self }
}
