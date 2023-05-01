//
//  FNConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FNConnection: FNConnectionProtocol {
    public var stateUpdateHandler: (FNConnectionState) -> Void = { _ in }
    
    private var transmitter: (FNConnectionTransmitter) -> Void = { _ in }
    private var frame = FNConnectionFrame()
    private let queue: DispatchQueue
    private var connection: NWConnection
    private var monitor = NWPathMonitor()
    private var timer: DispatchSourceTimer?
    
    /// create a new connection with 'FusionKit'
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - queue: dispatch queue
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString)) {
        if host.isEmpty { fatalError(FNConnectionError.missingHost.description) }
        if port == .zero { fatalError(FNConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// start a connection to a host
    /// creates a async tcp connection
    public func start() -> Void {
        timeout(); handler(); receive(); satisfied()
        monitor.start(queue: .init(label: UUID().uuidString))
    }
    
    /// cancel the connection
    /// closes the tcp connection and cleanup
    public func cancel() -> Void {
        cleanup()
    }
    
    /// send messages to a connected host
    /// - Parameter message: generic type send 'Text', 'Data' and 'Ping'
    public func send<T: FNConnectionMessage>(message: T) -> Void {
        let message = frame.create(message: message)
        if let error = message.error { stateUpdateHandler(.failed(error)); cleanup() }
        guard let data = message.data else { return }
        let queued = data.chunks
        guard !queued.isEmpty else { return }
        for data in queued { processing(with: data) }
    }
    
    /// receive a message from a connected host
    /// - Parameter completion: contains `FNConnectionMessage` and `FNConnectionBytes` generic message typ
    public func receive(_ completion: @escaping (FNConnectionMessage?, FNConnectionBytes?) -> Void) -> Void {
        transmitter = { state in
            switch state {
            case .message(let message): completion(message, nil)
            case .bytes(let bytes): completion(nil, bytes) }
        }
    }
}

// MARK: - Private API -

private extension FNConnection {
    /// start timeout and cancel connection
    /// if timeout value is reached
    private func timeout() -> Void {
        timer = Timer.timeout { [weak self] in
            guard let self else { return }
            cleanup(); stateUpdateHandler(.failed(FNConnectionError.connectionTimeout))
        }
    }
    
    /// cancel a running timeout
    private func invalidate() -> Void {
        guard let timer else { return }
        timer.cancel(); self.timer = nil
    }
    
    /// check if path is available
    private func satisfied() -> Void {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            switch path.status {
            case .satisfied: connection.start(queue: queue)
            case .unsatisfied: cleanup(); stateUpdateHandler(.failed(FNConnectionError.connectionUnsatisfied))
            default: break }
        }
    }
    
    /// process message data and send it to a host
    /// - Parameter data: message data
    private func processing(with data: Data) -> Void {
        connection.batch {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                transmitter(.bytes(FNConnectionBytes(output: data.count)))
                guard let error, error != NWError.posix(.ECANCELED) else { return }
                stateUpdateHandler(.failed(error))
            })
        }
    }
    
    /// process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processing(from data: Data) -> Void {
        frame.parse(data: data) { [weak self] message, error in
            guard let self else { return }
            if let message { transmitter(.message(message)) }
            guard let error else { return }
            stateUpdateHandler(.failed(error)); cleanup()
        }
        transmitter(.bytes(FNConnectionBytes(input: data.count)))
    }
    
    /// clean and cancel connection
    /// clear instance
    private func cleanup() -> Void {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            invalidate()
            connection.cancel()
            frame.reset()
        }
    }
    
    /// connection state update handler
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
    
    /// receives tcp data and parse it into a message frame
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
