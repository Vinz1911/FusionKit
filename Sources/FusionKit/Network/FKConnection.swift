//
//  FKConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FKConnection: FKConnectionProtocol {
    public var stateUpdateHandler: (FKConnectionState) -> Void = { _ in }
    
    private var transmitter: (FKTransmitter) -> Void = { _ in }
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FKConnectionFramer()
    private let connection: NWConnection
    private let monitor = NWPathMonitor()
    
    /// The `FKConnection` is a custom Network protocol implementation of the Fusion Framing Protocol.
    /// It's build on top of the `Network.framework` provided by Apple. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows to measure a Networks's performance.
    ///
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString)) {
        if host.isEmpty { fatalError(FKConnectionError.missingHost.description) }
        if port == .zero { fatalError(FKConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// Start a connection
    public func start() -> Void {
        timeout(); handler(); receive(); satisfied()
        monitor.start(queue: queue)
    }
    
    /// Cancel the current connection
    public func cancel() -> Void {
        cleanup()
    }
    
    /// Send messages to a connected host
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    public func send<T: FKConnectionMessage>(message: T) -> Void {
        queue.async { [weak self] in
            guard let self else { return }
            let message = framer.create(message: message)
            switch message {
            case .success(let data): let queued = data.chunks; if !queued.isEmpty { for data in queued { processing(with: data) } }
            case .failure(let error): stateUpdateHandler(.failed(error)); cleanup() }
        }
    }
    
    /// Receive a message from a connected host
    /// - Parameter completion: contains `FKConnectionMessage` and `FKConnectionBytes` generic message typ
    public func receive(_ completion: @escaping (FKConnectionMessage?, FKConnectionBytes?) -> Void) -> Void {
        transmitter = { result in
            switch result {
            case .message(let message): completion(message, nil)
            case .bytes(let bytes): completion(nil, bytes) }
        }
    }
}

// MARK: - Private API -

private extension FKConnection {
    /// Start timeout and cancel connection,
    /// if timeout value is reached
    private func timeout() -> Void {
        timer = Timer.timeout { [weak self] in
            guard let self else { return }
            cleanup(); stateUpdateHandler(.failed(FKConnectionError.connectionTimeout))
        }
    }
    
    /// Cancel a running timeout
    private func invalidate() -> Void {
        guard let timer else { return }
        timer.cancel(); self.timer = nil
    }
    
    /// Check if path is available
    private func satisfied() -> Void {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            switch path.status {
            case .satisfied: connection.start(queue: queue)
            case .unsatisfied: cleanup(); stateUpdateHandler(.failed(FKConnectionError.connectionUnsatisfied))
            default: break }
        }
    }
    
    /// Process message data and send it to a host
    /// - Parameter data: message data
    private func processing(with data: Data) -> Void {
        connection.batch {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                transmitter(.bytes(FKConnectionBytes(output: data.count)))
                guard let error, error != NWError.posix(.ECANCELED) else { return }
                stateUpdateHandler(.failed(error))
            })
        }
    }
    
    /// Process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processing(from data: Data) -> Void {
        framer.parse(data: data) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message): transmitter(.message(message))
            case .failure(let error): stateUpdateHandler(.failed(error)); cleanup() }
        }
        transmitter(.bytes(.init(input: data.count)))
    }
    
    /// Clean and cancel connection
    private func cleanup() -> Void {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            invalidate()
            monitor.cancel()
            connection.cancel()
            framer.reset()
        }
    }
    
    /// Connection state update handler,
    /// handles different network connection states
    private func handler() -> Void {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .cancelled: stateUpdateHandler(.cancelled)
            case .failed(let error), .waiting(let error): stateUpdateHandler(.failed(error)); cleanup()
            case .ready: stateUpdateHandler(.ready); invalidate()
            default: break }
        }
    }
    
    /// Receives tcp data and parse it into a message frame
    private func receive() -> Void {
        connection.batch {
            connection.receive(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] data, _, isComplete, error in
                guard let self else { return }
                if let error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    stateUpdateHandler(.failed(error)); cleanup()
                    return
                }
                if let data { processing(from: data) }
                if isComplete { cleanup() } else { receive() }
            }
        }
    }
}
