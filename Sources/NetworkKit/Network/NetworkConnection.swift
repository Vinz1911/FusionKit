//
//  Connection.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class NetworkConnection: NetworkConnectionProtocol {
    
    /// result type
    public var stateUpdateHandler: (NetworkConnectionResult) -> Void = { _ in }
    
    private let overheadByteCount: Int = 0x5
    private let frameByteCount: Int = 0x2000
    
    private var connection: NWConnection?
    private let frame: NetworkFrame = NetworkFrame()
    private var queue: DispatchQueue
    private var processed: Bool = true
    
    /// create instance of the 'ClientConnection' class
    /// this class handles raw tcp connection
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - qos: dispatch qos, default is background
    required public init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .background) {
        if host.isEmpty { fatalError(NetworkConnectionError.missingHost.description) }
        if port == .zero { fatalError(NetworkConnectionError.missingPort.description) }
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = DispatchQueue(label: UUID().uuidString, qos: qos)
    }
    
    /// start a connection to a host
    /// creates a async tcp connection
    public func start() {
        guard let connection = connection else { return }
        stateHandler()
        receive()
        connection.start(queue: queue)
    }
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    public func cancel() {
        cleanup()
    }
    
    /// send messages to a connected host
    /// - Parameters:
    ///   - message: generic type, accepts 'String' & 'Data'
    ///   - completion: callback when sending is completed
    public func send<T: NetworkMessage>(message: T, _ completion: (() -> Void)? = nil) {
        let result = frame.create(message: message)
        if let error = result.error {
            stateUpdateHandler(.didGetError(error))
            cleanup()
        }
        guard let data = result.data else { return }
        processingMessage(data: data) {
            guard let completion = completion else { return }
            completion()
        }
    }
}

// MARK: - Private API Extension

private extension NetworkConnection {
    
    /// process message data and send it to a host
    /// - Parameters:
    ///   - data: message data
    ///   - completion: callback on complete
    private func processingMessage(data: Data, _ completion: @escaping () -> Void) {
        guard let connection = connection else { return }
        guard processed else { return }
        processed = false
        let queued = data.chunk
        guard !queued.isEmpty else { return }
        for (i, data) in queued.enumerated() {
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    self.stateUpdateHandler(.didGetError(error))
                    return
                }
                self.stateUpdateHandler(.didGetBytes(NetworkBytes(output: data.count)))
                if i == queued.endIndex - 1 {
                    self.processed = true
                    completion()
                }
            }))
        }
    }
    
    /// clean and cancel connection
    /// clear instance
    private func cleanup() {
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
            case .ready: self.stateUpdateHandler(.didGetReady)
            case .failed(let error):
                self.stateUpdateHandler(.didGetError(error))
                self.cleanup()
            case .cancelled: self.stateUpdateHandler(.didGetCancelled)
            default: break
            }
        }
    }
    
    /// receive pure data frames
    /// handles traffic input
    private func receive() {
        guard let connection = connection else { return }
        connection.receive(minimumIncompleteLength: overheadByteCount, maximumLength: frameByteCount) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                guard error != NWError.posix(.ECANCELED) else { return }
                self.stateUpdateHandler(.didGetError(error))
                self.cleanup()
                return
            }
            if let data = data {
                self.stateUpdateHandler(.didGetBytes(NetworkBytes(input: data.count)))
                let error = self.frame.parse(data: data) { message in
                    guard let message = message else { return }
                    self.stateUpdateHandler(.didGetMessage(message))
                }
                if let error = error {
                    self.stateUpdateHandler(.didGetError(error))
                    self.cleanup()
                }
            }
            if isComplete { self.cleanup() } else { self.receive() }
        }
    }
}
