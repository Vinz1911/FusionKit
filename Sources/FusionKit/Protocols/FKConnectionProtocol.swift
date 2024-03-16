//
//  FKConnectionProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FKConnectionProtocol: Sendable {
    /// The `FKConnectionState` update values
    var stateUpdateHandler: (@Sendable (FKConnectionState) -> Void) { get set }
    
    /// The `FKConnection` is a custom Network protocol implementation of the Fusion Framing Protocol.
    /// It's build on top of the `Network.framework` provided by Apple. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows to measure a Networks's performance.
    ///
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    init(host: String, port: UInt16, parameters: NWParameters, queue: DispatchQueue)
    
    /// Start a connection
    func start() -> Void
    
    /// Cancel the current connection
    func cancel() -> Void
    
    /// Send messages to a connected host
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    func send<T: FKConnectionMessage>(message: T) -> Void
    
    /// Receive a message from a connected host
    /// - Parameter completion: contains `FKConnectionMessage` and `FKConnectionBytes` generic message typ
    func receive(_ completion: @escaping (FKConnectionMessage?, FKConnectionBytes?) -> Void) -> Void
}
