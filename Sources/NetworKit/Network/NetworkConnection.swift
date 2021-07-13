//
//  NetworkConnection.swift
//  NetworKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class NetworkConnection: NetworkConnectionProtocol {
    
    public var stateUpdateHandler: (NetworkConnectionResult) -> Void = { _ in }
    
    private var frame: NetworkFrame?
    private let queue: DispatchQueue
    private var connection: NWConnection
    private var timer: DispatchSourceTimer?
    
    /// create instance of the 'ClientConnection' class
    /// this class handles raw tcp connection
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    required public init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString)) {
        if host.isEmpty { fatalError(NetworkConnectionError.missingHost.description) }
        if port == .zero { fatalError(NetworkConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// start a connection to a host
    /// creates a async tcp connection
    public func start() {
        frame = NetworkFrame()
        stateHandler()
        startTimeout()
        receiveMessage()
        connection.start(queue: queue)
    }
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    public func cancel() {
        cleanup()
    }
    
    /// send messages to a connected host
    /// - Parameters:
    ///   - message: generic type send 'Text', 'Data' and 'Ping'
    public func send<T: NetworkMessage>(message: T) {
        guard let frame = frame else { return }
        let message = frame.create(message: message)
        if let error = message.error {
            stateUpdateHandler(.failed(error))
            cleanup()
        }
        guard let data = message.data else { return }
        let queued = data.chunks
        guard !queued.isEmpty else { return }
        for data in queued { processingSendMessage(data: data) }
    }
}

// MARK: - Private API Extension

private extension NetworkConnection {
    
    /// start timeout and cancel connection
    /// if timeout value is reached
    private func startTimeout() {
        self.timer = Timer.timeout { [weak self] in
            guard let self = self else { return }
            self.cleanup()
            self.stateUpdateHandler(.failed(NetworkConnectionError.connectionTimeout))
        }
    }
    
    /// cancel a running timeout
    private func cancelTimeout() {
        guard let timer = self.timer else { return }
        timer.cancel()
        self.timer = nil
    }
    
    /// process message data and send it to a host
    /// - Parameters:
    ///   - data: message data
    private func processingSendMessage(data: Data) {
        connection.batch {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self = self else { return }
                self.stateUpdateHandler(.bytes(NetworkBytes(output: data.count)))
                guard let error = error, error != NWError.posix(.ECANCELED) else { return }
                self.stateUpdateHandler(.failed(error))
            })
        }
    }
    
    /// process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processingParseMessage(data: Data) {
        guard let frame = frame else { return }
        frame.parse(data: data) { message, error in
            if let message = message { stateUpdateHandler(.message(message)) }
            guard let error = error else { return }
            stateUpdateHandler(.failed(error))
            cleanup()
        }
        stateUpdateHandler(.bytes(NetworkBytes(input: data.count)))
    }
    
    /// clean and cancel connection
    /// clear instance
    private func cleanup() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.cancelTimeout()
            self.connection.cancel()
            self.frame = NetworkFrame()
        }
    }
    
    /// connection state handler
    /// handles different network connection states
    private func stateHandler() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .cancelled: self.stateUpdateHandler(.cancelled)
            case .failed(let error), .waiting(let error):
                self.stateUpdateHandler(.failed(error))
                self.cleanup()
            case .ready:
                self.stateUpdateHandler(.ready)
                self.cancelTimeout()
            default: break }
        }
    }
    
    /// receives tcp data and parse it into a message frame
    private func receiveMessage() {
        connection.batch {
            connection.receive(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] data, _, isComplete, error in
                guard let self = self else { return }
                if let error = error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    self.stateUpdateHandler(.failed(error))
                    self.cleanup()
                    return
                }
                if let data = data { self.processingParseMessage(data: data) }
                if isComplete { self.cleanup() } else { self.receiveMessage() }
            }
        }
    }
}
