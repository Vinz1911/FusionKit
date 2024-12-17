//
//  FKMessage.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FKMessage` protocol for message compliance
public protocol FKMessage: Sendable {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// Conformance to protocol `FKMessage`
extension UInt16: FKMessage {
    public var opcode: UInt8 { FKOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// Conformance to protocol `FKMessage`
extension String: FKMessage {
    public var opcode: UInt8 { FKOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// Conformance to protocol `FKMessage`
extension Data: FKMessage {
    public var opcode: UInt8 { FKOpcodes.binary.rawValue }
    public var raw: Data { self }
}
