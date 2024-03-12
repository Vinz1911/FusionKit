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
    private var ready: (Error?) -> Void = { _ in }
    private var failed: (Error?) -> Void = { _ in }
    private var transmitter: (FKConnectionResult) -> Void = { _ in }
    
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FKConnectionFramer()
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
        if host.isEmpty { fatalError(FKConnectionError.missingHost.description) }; if port == .zero { fatalError(FKConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// Start a connection
    public func start() async throws -> Void {
        return try await withCheckedThrowingContinuation { [weak self] continuation in guard let self else { return }
            ready = { if let error = $0 { continuation.resume(throwing: error) } else { continuation.resume() } }
            timeout(); handler(); discontiguous()
            connection.start(queue: queue)
        }
    }
    
    /// Cancel the current connection
    public func cancel() -> Void {
        self.queue.async { [weak self] in guard let self else { return }
            invalidate(); framer.reset(); connection.cancel()
        }
    }
    
    /// Send messages to a connected host
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    public func send<T: FKConnectionMessage>(message: T) async -> Void {
        return await withCheckedContinuation { [weak self] continuation in guard let self else { return }
            self.queue.async { [weak self] in guard let self else { return }
                self.processing(with: message); continuation.resume()
            }
        }
    }
    
    /// Receive a message from a connected host
    /// - Parameter completion: contains `FKConnectionMessage` and `FKConnectionBytes` generic message typ
    public func receive() -> AsyncThrowingStream<FKConnectionResult, Error> {
        return AsyncThrowingStream { [weak self] continuation in guard let self else { return }
            self.queue.async { [weak self] in guard let self else { return }
                transmitter = { continuation.yield(with: .success($0)) }
                failed = { if let error = $0 { continuation.finish(throwing: error) } }
            }
        }
    }
}

// MARK: - Private API -

private extension FKConnection {
    /// Start timeout and cancel connection,
    /// if timeout value is reached
    private func timeout() -> Void {
        timer = Timer.timeout(queue: queue) { [weak self] in
            guard let self else { return }
            cancel(); ready(FKConnectionError.connectionTimeout)
        }
    }
    
    /// Cancel a running timeout
    private func invalidate() -> Void {
        guard let timer else { return }
        timer.cancel(); self.timer = nil
    }
    
    /// Process message data and send it to a host
    /// - Parameter data: message data
    private func processing<T: FKConnectionMessage>(with message: T) -> Void {
        let message = framer.create(message: message)
        switch message {
        case .success(let data): let queued = data.chunks; if !queued.isEmpty { for data in queued { transmission(with: data) } }
        case .failure(let error): failed(error); cancel() }
    }
    
    /// Process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processing(from data: DispatchData) -> Void {
        transmitter(.bytes(.init(input: data.count)))
        framer.parse(data: data) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message): transmitter(.message(message))
            case .failure(let error): failed(error); cancel() }
        }
    }
    
    /// Connection state update handler,
    /// handles different network connection states
    private func handler() -> Void {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .cancelled: failed(nil)
            case .failed(let error), .waiting(let error): cancel(); failed(error)
            case .ready: invalidate(); ready(nil)
            default: break }
        }
    }
    
    /// Transmit tcp data frames
    /// - Parameter data: the `Data` to transmit
    private func transmission(with data: Data) -> Void {
        connection.batch {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                transmitter(.bytes(FKConnectionBytes(output: data.count)))
                guard let error, error != NWError.posix(.ECANCELED) else { return }; failed(error)
            })
        }
    }
    
    /// Receives tcp data frames
    private func discontiguous() -> Void {
        connection.batch {
            connection.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] data, _, isComplete, error in
                guard let self else { return }
                if let error { guard error != NWError.posix(.ECANCELED) else { return }; failed(error); cancel(); return }
                if let data { processing(from: data) }
                if isComplete { cancel() } else { discontiguous() }
            }
        }
    }
}
