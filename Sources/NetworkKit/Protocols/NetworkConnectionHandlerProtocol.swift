//
//  ClientConnectionProtocol.swift
//
//  NetworkKit
//
//  Created by Vinzenz Weist on 02.04.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
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
    
    /// open a connection to a host
    /// creates a async tcp connection
    func openConnection()

    /// close the connection
    /// closes the tcp connection and cleanup
    func closeConnection()

    /// send messages to a host
    /// send raw data
    /// - Parameters:
    ///   - data: raw data
    ///   - completion: callback when sending is completed
    func send(data: Data, _ completion: @escaping () -> Void)
}
