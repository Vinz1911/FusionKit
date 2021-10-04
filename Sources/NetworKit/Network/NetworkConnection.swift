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
    private var frame = NetworkFrame()
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
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString)) {
        if host.isEmpty { fatalError(NetworkConnectionError.missingHost.description) }
        if port == .zero { fatalError(NetworkConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// start a connection to a host
    /// creates a async tcp connection
    public func start() {
        timeout(); handler(); receive()
        connection.start(queue: queue)
    }
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    public func cancel() {
        cleanup()
    }
    
    /// send messages to a connected host
    /// - Parameter message: generic type send 'Text', 'Data' and 'Ping'
    public func send<T: NetworkMessage>(message: T) {
        let message = frame.create(message: message)
        if let error = message.error { stateUpdateHandler(.failed(error)); cleanup() }
        guard let data = message.data else { return }
        let queued = data.chunks
        guard !queued.isEmpty else { return }
        for data in queued { processing(with: data) }
    }
}

// MARK: - Private API -

private extension NetworkConnection {
    /// start timeout and cancel connection
    /// if timeout value is reached
    private func timeout() {
        self.timer = Timer.timeout { [weak self] in
            guard let self = self else { return }
            self.cleanup()
            self.stateUpdateHandler(.failed(NetworkConnectionError.connectionTimeout))
        }
    }
    
    /// cancel a running timeout
    private func invalidate() {
        guard let timer = self.timer else { return }
        timer.cancel(); self.timer = nil
    }
    
    /// process message data and send it to a host
    /// - Parameter data: message data
    private func processing(with data: Data) {
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
    private func processing(from data: Data) {
        frame.parse(data: data) { message, error in
            if let message = message { stateUpdateHandler(.message(message)) }
            guard let error = error else { return }
            stateUpdateHandler(.failed(error)); cleanup()
        }
        stateUpdateHandler(.bytes(NetworkBytes(input: data.count)))
    }
    
    /// clean and cancel connection
    /// clear instance
    private func cleanup() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.invalidate()
            self.connection.cancel()
            self.frame.reset()
        }
    }
    
    /// connection state update handler
    /// handles different network connection states
    private func handler() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .cancelled: self.stateUpdateHandler(.cancelled)
            case .failed(let error), .waiting(let error): self.stateUpdateHandler(.failed(error)); self.cleanup()
            case .ready: self.stateUpdateHandler(.ready); self.invalidate()
            default: break }
        }
    }
    
    /// receives tcp data and parse it into a message frame
    private func receive() {
        connection.batch {
            connection.receive(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] data, _, isComplete, error in
                guard let self = self else { return }
                if let error = error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    self.stateUpdateHandler(.failed(error)); self.cleanup()
                    return
                }
                if let data = data { self.processing(from: data) }
                if isComplete { self.cleanup() } else { self.receive() }
            }
        }
    }
}
