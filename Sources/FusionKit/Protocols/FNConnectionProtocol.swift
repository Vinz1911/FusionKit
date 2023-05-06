//
//  FNConnectionProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FNConnectionProtocol {
    /// Access to connection State's
    var stateUpdateHandler: (FNConnectionState) -> Void { get set }
    
    /// The `FNConnection` is a custom Network protocol implementation of the Fusion Framing Protocol.
    /// It's build on top of the `Network.framework` provided by Apple. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows to measure a Networks's performance.
    ///
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    init(host: String, port: UInt16, parameters: NWParameters, queue: DispatchQueue)
    
    /// Start a connecting to a host
    func start() -> Void
    
    /// Cancel the current connection
    func cancel() -> Void
    
    /// Send messages to a connected host
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    func send<T: FNConnectionMessage>(message: T) -> Void
    
    /// Receive a message from a connected host
    /// - Parameter completion: contains `FNConnectionMessage` and `FNConnectionBytes` generic message typ
    func receive(_ completion: @escaping (FNConnectionMessage?, FNConnectionBytes?) -> Void) -> Void
}
