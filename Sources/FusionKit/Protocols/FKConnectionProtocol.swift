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
    var stateUpdateHandler: (@Sendable (FKState) -> Void) { get set }
    
    /// The `FKConnection` is a custom network framing protocol and implements the `Fusion Framing Protocol`.
    /// It's build on top of the `Network` framework standard library. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows a more fine grained control over the network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    init(host: String, port: UInt16, parameters: NWParameters, qos: DispatchQoS) throws
    
    /// Start a connection
    ///
    /// - Returns: non returning
    func start() -> Void
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    func cancel() -> Void
    
    /// Send messages to a connected host
    ///
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    func send<T: FKMessage>(message: T) -> Void
    
    /// Receive a message from a connected host
    /// 
    /// - Parameter completion: contains `FKMessage` and `FKBytes` generic message typ
    func receive(_ completion: @Sendable @escaping (FKMessage?, FKBytes?) -> Void) -> Void
}
