//
//  NetworkConnection.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 25.03.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class NetworkConnection: NetworkConnectionProtocol {
    
    public var state: (NetworkConnectionResult) -> Void = { _ in }
    public var parameters: NWParameters = .tcp
    
    private var host: String
    private var port: UInt16
    private var qos: DispatchQoS
    private var frame: NetworkFrame = NetworkFrame()
    private var connection: NetworkConnectionHandler?
    
    /// create a new connection with 'NetworkKit'
    /// - Parameters:
    ///   - host: the host to connect
    ///   - port: the port of the host
    ///   - qos: qos class, default is background
    public required init(host: String, port: UInt16, qos: DispatchQoS = .background) {
        self.host = host
        self.port = port
        self.qos = qos
    }
    
    /// open a connection to a host
    /// creates a async tcp connection
    public func openConnection() {
        prepareConnection()
        guard let connection = connection else { return }
        connection.openConnection()
    }
    
    /// close the connection
    /// closes the tcp connection and cleanup
    public func closeConnection() {
        cleanConnection()
    }
    
    /// send messages to a connected host
    /// - Parameters:
    ///   - message: generic type, accepts 'String' & 'Data'
    ///   - completion: callback when sending is completed
    public func send<T: NetworkMessage>(message: T, _ completion: (() -> Void)? = nil) {
        guard let connection = connection else { return }
        let data = self.frame.create(message: message) { error in
            state(.didGetError(error))
            cleanConnection()
        }
        connection.send(data: data) {
            guard let completion = completion else { return }
            completion()
        }
    }
}

// MARK: - Private API Extension

private extension NetworkConnection {
    
    /// clean up the connection
    /// reset the instance
    private func cleanConnection() {
        guard let connection = connection else {
            return
        }
        connection.closeConnection()
        self.connection = nil
    }

    /// prepare the client connection
    /// check if host and port are correct
    /// starts to listen on callback
    private func prepareConnection() {
        guard !host.isEmpty else {
            state(.didGetError(NetworkConnectionError.missingHost))
            return
        }
        guard port != .zero else {
            state(.didGetError(NetworkConnectionError.missingPort))
            return
        }
        connection = NetworkConnectionHandler(host: host, port: port, parameters: parameters, qos: qos)
        peerConnectionHandle()
    }
    
    /// handle the peer connection results
    /// parse raw data in 'Message' conform data
    private func peerConnectionHandle() {
        guard let connection = connection else { return }
        connection.state = { state in
            switch state {
            case .didGetReady: self.state(.didGetReady)
            case .didGetCancelled: self.state(.didGetCancelled)
            case .didGetError(let error):
                self.state(.didGetError(error))
                self.cleanConnection()
            case .didGetBytes(let bytes): self.state(.didGetBytes(bytes))
            case .didGetData(let data):
                self.frame.parse(data: data) { message, error in
                    if let error = error {
                        self.state(.didGetError(error))
                        self.cleanConnection()
                    }
                    if let message = message { self.state(.didGetMessage(message)) }
                }
            }
        }
    }
}
