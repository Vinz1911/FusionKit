//
//  NetworkMessage.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 03.05.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//

import Foundation

/// protocol for message compliance
public protocol NetworkMessage {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// conformance to protocol 'Message'
extension String: NetworkMessage {
    public var opcode: UInt8 { NetworkOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// conformance to protocol 'Message'
extension Data: NetworkMessage {
    public var opcode: UInt8 { NetworkOpcodes.binary.rawValue }
    public var raw: Data { self }
}
