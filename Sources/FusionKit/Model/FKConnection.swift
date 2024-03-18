//
//  FKConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FKConnection: FKConnectionProtocol, @unchecked Sendable {
    public var stateUpdateHandler: (@Sendable (FKState) -> Void) = { _ in }
    private var result: (@Sendable (FKResult) -> Void) = { _ in }
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FKFramer()
    private let connection: NWConnection
    
    /// The `FKConnection` is a custom Network protocol implementation of the Fusion Framing Protocol.
    /// It's build on top of the `Network.framework` provided by Apple. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows to measure a Networks's performance.
    ///
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString, qos: .userInteractive)) {
        if host.isEmpty { fatalError(FKError.missingHost.description) }; if port == .zero { fatalError(FKError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// Start a connection
    public func start() -> Void {
        queue.async { [weak self] in guard let self else { return }
            timeout(); handler(); discontiguous(); connection.start(queue: queue)
        }
    }
    
    /// Cancel the current connection
    public func cancel() -> Void {
        self.queue.async { [weak self] in guard let self else { return }
            cleanup()
        }
    }
    
    /// Send messages to a connected host
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    public func send<T: FKMessage>(message: T) -> Void {
        self.queue.async { [weak self] in guard let self else { return }
            processing(with: message)
        }
    }
    
    /// Receive a message from a connected host
    /// - Parameter completion: contains `FKMessage` and `FKBytes` generic message typ
    public func receive(_ completion: @Sendable @escaping (FKMessage?, FKBytes?) -> Void) -> Void {
        result = { if case .message(let message) = $0 { completion(message, nil) }; if case .bytes(let bytes) = $0 { completion(nil, bytes) } }
    }
}

// MARK: - Private API -

private extension FKConnection {
    /// Start timeout and cancel connection,
    /// if timeout value is reached
    private func timeout() -> Void {
        timer = Timer.timeout(queue: queue) { [weak self] in
            guard let self else { return }
            cleanup(); stateUpdateHandler(.failed(FKError.connectionTimeout))
        }
    }
    
    /// Cancel a running timeout
    private func invalidate() -> Void {
        guard let timer else { return }
        timer.cancel(); self.timer = nil
    }
    
    /// Process message data and send it to a host
    /// - Parameter data: message data
    private func processing<T: FKMessage>(with message: T) -> Void {
        let message = framer.create(message: message)
        switch message {
        case .success(let data): let queued = data.chunks; if !queued.isEmpty { for data in queued { transmission(data)} }
        case .failure(let error): stateUpdateHandler(.failed(error)); cleanup() }
    }
    
    /// Process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processing(from data: DispatchData) -> Void {
        result(.bytes(.init(input: data.count)))
        framer.parse(data: data) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message): self.result(.message(message))
            case .failure(let error): stateUpdateHandler(.failed(error)); cleanup() }
        }
    }
    
    /// Clean and cancel connection
    private func cleanup() -> Void {
        invalidate(); framer.reset(); connection.cancel()
    }
    
    /// Connection state update handler,
    /// handles different network connection states
    private func handler() -> Void {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .cancelled: stateUpdateHandler(.cancelled)
            case .failed(let error), .waiting(let error): cleanup(); stateUpdateHandler(.failed(error))
            case .ready: invalidate(); stateUpdateHandler(.ready)
            default: break }
        }
    }
    
    /// Transmit tcp data from a message frame
    /// - Parameter content: the content `Data` to transmit
    private func transmission(_ content: Data) -> Void {
        connection.batch {
            connection.send(content: content, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                result(.bytes(FKBytes(output: content.count)))
                if let error, error != NWError.posix(.ECANCELED) { stateUpdateHandler(.failed(error)) }
            })
        }
    }
    
    /// Receives tcp data and parse it into a message frame
    private func discontiguous() -> Void {
        connection.batch {
            connection.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] content, _, isComplete, error in
                guard let self else { return }
                if let error { guard error != NWError.posix(.ECANCELED) else { return }; stateUpdateHandler(.failed(error)); cleanup(); return }
                if let content { processing(from: content) }
                if isComplete { cleanup() } else { discontiguous() }
            }
        }
    }
}
