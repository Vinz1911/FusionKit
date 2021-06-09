//
//  ClientConnectionProtocol.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//
import Foundation
import Network

internal protocol NetworkConnectionHandlerProtocol {
    
    var state: (NetworkConnectionHandlerResult) -> Void { get set }
    /// create instance of the 'ClientConnection' class
    /// this class handles raw tcp connection
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - qos: dispatch qos, default is background
    init(host: String, port: UInt16, parameters: NWParameters, qos: DispatchQoS)
    
    /// start a connection to a host
    /// creates a async tcp connection
    func start()

    /// cancel the connection
    /// closes the tcp connection and cleanup
    func cancel()

    /// send messages to a host
    /// send raw data
    /// - Parameters:
    ///   - data: raw data
    ///   - completion: callback when sending is completed
    func send(data: Data, _ completion: @escaping () -> Void)
}
