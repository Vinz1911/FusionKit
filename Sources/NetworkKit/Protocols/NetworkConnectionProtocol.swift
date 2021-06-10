//
//  NetworkConnectionProtocol.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol NetworkConnectionProtocol {
    
    /// result type
    var stateUpdateHandler: (NetworkConnectionResult) -> Void { get set }
    
    /// create a new connection with 'NetworkKit'
    /// - Parameters:
    ///   - host: the host to connect
    ///   - port: the port of the host
    ///   - qos: qos class, default is background
    init(host: String, port: UInt16, parameters: NWParameters, qos: DispatchQoS)
    
    /// start a connection to a host
    /// creates a async tcp connection
    func start()
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    func cancel()
    
    /// send messages to a connected host
    /// - Parameters:
    ///   - message: generic type, accepts 'String' and 'Data'
    ///   - completion: callback when sending is completed
    func send<T: NetworkMessage>(message: T, _ completion: (() -> Void)?)
}
