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
    /// result type
    var stateUpdateHandler: (FNConnectionState) -> Void { get set }
    
    /// create a new connection with 'FusionKit'
    /// - Parameters:
    ///   - host: the host to connect
    ///   - port: the port of the host
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    init(host: String, port: UInt16, parameters: NWParameters, queue: DispatchQueue)
    
    /// start a connection to a host
    /// creates a async tcp connection
    func start()
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    func cancel()
    
    /// send messages to a connected host
    /// - Parameter message: generic type send 'Text', 'Data' and 'Ping'
    func send<T: FNConnectionMessage>(message: T)
}
