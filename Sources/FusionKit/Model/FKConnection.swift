//
//  FKConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network
import os

public final class FKConnection: FKConnectionProtocol, @unchecked Sendable {
    public private(set) var state: FKConnectionState = .closed
    private var intercom: (FKConnectionIntercom) -> Void = { _ in }
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FKConnectionFramer()
    private let connection: NWConnection
    private let lock = OSAllocatedUnfairLock()
    
    /// The `FKConnection` is a custom Network protocol implementation of the Fusion Framing Protocol.
    /// It's build on top of the `Network.framework` provided by Apple. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows to measure a Networks's performance.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the network port as `UInt16`
    ///   - parameters: network frameworks `NWParameters`
    ///   - qos: quality of service as `DispatchQoS`
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .userInteractive) {
        if host.isEmpty { fatalError(FKConnectionError.missingHost.description) }; if port == .zero { fatalError(FKConnectionError.missingPort.description) }
        self.connection = .init(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = .init(label: UUID().uuidString, qos: qos)
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
                intercom = { [weak self] result in guard let self else { return }
                    lock.withLock { [weak self] in guard let self else { return }
                        switch result {
                        case .ready: state = .ready
                        case .failed(let error): state = .closed; continuation.finish(throwing: error)
                        case .result(let result): continuation.yield(with: .success(result)) }
                    }
                }
                timeout(); handler(); discontiguous(); connection.start(queue: queue)
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
            cancel(); intercom(.failed(FKConnectionError.connectionTimeout))
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
        case .failure(let error): intercom(.failed(error)); cancel() }
    }
    
    /// Process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processing(from data: DispatchData) -> Void {
        intercom(.result(.bytes(.init(input: data.count))))
        framer.parse(data: data) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message): intercom(.result(.message(message)))
            case .failure(let error): intercom(.failed(error)); cancel() }
        }
    }
    
    /// Connection state update handler,
    /// handles different network connection states
    private func handler() -> Void {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .cancelled: intercom(.failed(nil))
            case .failed(let error), .waiting(let error): intercom(.failed(error)); cancel()
            case .ready: invalidate(); intercom(.ready)
            default: break }
        }
    }
    
    /// Transmit tcp data frames
    /// - Parameter data: the `Data` to transmit
    private func transmission(with data: Data) -> Void {
        connection.batch {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                intercom(.result(.bytes(FKConnectionBytes(output: data.count))))
                guard let error, error != NWError.posix(.ECANCELED) else { return }; intercom(.failed(error))
            })
        }
    }
    
    /// Receives tcp data frames
    private func discontiguous() -> Void {
        connection.batch {
            connection.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] data, _, isComplete, error in
                guard let self else { return }
                if let error { guard error != NWError.posix(.ECANCELED) else { return }; intercom(.failed(error)); cancel(); return }
                if let data { processing(from: data) }
                if isComplete { cancel() } else { discontiguous() }
            }
        }
    }
}
