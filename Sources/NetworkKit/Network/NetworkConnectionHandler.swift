//
//  Connection.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 25.03.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

internal final class NetworkConnectionHandler: NetworkConnectionHandlerProtocol {
    
    internal var state: (NetworkConnectionHandlerResult) -> Void = { _ in }
    
    private let overheadByteCount: Int = MemoryLayout<UInt32>.size + 1
    private let frameByteCount: Int = Int(UInt32.max)
    
    private var connection: NWConnection?
    private var queue: DispatchQueue
    private var processed: Bool = true
    
    /// create instance of the 'ClientConnection' class
    /// this class handles raw tcp connection
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - qos: dispatch qos, default is background
    required init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .background) {
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = DispatchQueue(label: UUID().uuidString, qos: qos)
    }
    
    /// open a connection to a host
    /// creates a async tcp connection
    internal func openConnection() {
        guard let connection = connection else { return }
        stateHandler()
        receiveMessages()
        connection.start(queue: queue)
    }
    
    /// close the connection
    /// closes the tcp connection and cleanup
    internal func closeConnection() {
        cleanConnection()
    }

    /// send messages to a host
    /// send raw data
    /// - Parameters:
    ///   - data: raw data
    ///   - completion: callback when sending is completed
    internal func send(data: Data, _ completion: @escaping () -> Void) {
        guard let connection = connection else { return }
        guard processed else { return }
        processed = false
        let queued = data.chunk
        guard !queued.isEmpty else { return }
        for (i, data) in queued.enumerated() {
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    self.state(.didGetError(error))
                    return
                }
                self.state(.didGetBytes(NetworkBytes(output: data.count)))
                if i == queued.endIndex - 1 {
                    self.processed = true
                    completion()
                }
            }))
        }
    }
}

// MARK: - Private API Extension

private extension NetworkConnectionHandler {
    
    /// clean and cancel connection
    /// clear instance
    private func cleanConnection() {
        guard let connection = connection else { return }
        connection.cancel()
        self.connection = nil
    }
    
    /// connection state handler
    /// handles different network connection states
    private func stateHandler() {
        guard let connection = connection else { return }
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready: self.state(.didGetReady)
            case .failed(let error):
                self.state(.didGetError(error))
                self.cleanConnection()
            case .cancelled: self.state(.didGetCancelled)
            default: break
            }
        }
    }
    
    /// receive message frames
    /// handles traffic input
    private func receiveMessages() {
        guard let connection = connection else { return }
        connection.receive(minimumIncompleteLength: overheadByteCount, maximumLength: frameByteCount) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                guard error != NWError.posix(.ECANCELED) else { return }
                self.state(.didGetError(error))
                self.cleanConnection()
                return
            }
            if let data = data {
                self.state(.didGetData(data))
                self.state(.didGetBytes(NetworkBytes(input: data.count)))
            }
            if isComplete { self.cleanConnection() } else { self.receiveMessages() }
        }
    }
}
