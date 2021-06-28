//
//  NetworkConnection.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class NetworkConnection: NetworkConnectionProtocol {
    
    public var stateUpdateHandler: (NetworkConnectionResult) -> Void = { _ in }
    
    private let frame: NetworkFrame = NetworkFrame()
    private let queue: DispatchQueue
    private var connection: NWConnection
    private var processed: Bool = true
    private var timer: DispatchSourceTimer?
    
    /// create instance of the 'ClientConnection' class
    /// this class handles raw tcp connection
    /// - Parameters:
    ///   - host: the host name
    ///   - port: the host port
    ///   - parameters: network parameters
    ///   - qos: dispatch qos, default is background
    required public init(host: String, port: UInt16, parameters: NWParameters = .tcp, queue: DispatchQueue = .init(label: UUID().uuidString)) {
        if host.isEmpty { fatalError(NetworkConnectionError.missingHost.description) }
        if port == .zero { fatalError(NetworkConnectionError.missingPort.description) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = queue
    }
    
    /// start a connection to a host
    /// creates a async tcp connection
    public func start() {
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
    ///   - message: generic type, accepts 'String' and 'Data'
    ///   - completion: callback when sending is completed
    public func send<T: NetworkMessage>(message: T, _ completion: (() -> Void)? = nil) {
        let result = frame.create(message: message)
        if let error = result.error {
            stateUpdateHandler(.failed(error))
            cleanup()
        }
        guard let data = result.data else { return }
        processingSendMessage(data: data) {
            guard let completion = completion else { return }
            completion()
        }
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
    private func stopTimeout() {
        guard let timer = self.timer else { return }
        timer.cancel()
        self.timer = nil
    }
    
    /// process message data and send it to a host
    /// - Parameters:
    ///   - data: message data
    ///   - completion: callback on complete
    private func processingSendMessage(data: Data, _ completion: @escaping () -> Void) {
        guard processed else { return }
        processed = false
        let queued = data.chunks
        guard !queued.isEmpty else { return }
        for data in queued {
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    guard error != NWError.posix(.ECANCELED) else { return }
                    self.stateUpdateHandler(.failed(error))
                }
                self.stateUpdateHandler(.bytes(NetworkBytes(output: data.count)))
                if data == queued.last { self.processed = true; completion() }
            }))
        }
    }
    
    /// process message data and parse it into a conform message
    /// - Parameter data: message data
    private func processingParseMessage(data: Data) {
        self.frame.parse(data: data) { message, error in
            if let message = message { self.stateUpdateHandler(.message(message)) }
            if let error = error {
                self.stateUpdateHandler(.failed(error))
                self.cleanup()
            }
        }
        self.stateUpdateHandler(.bytes(NetworkBytes(input: data.count)))
    }
    
    /// clean and cancel connection
    /// clear instance
    private func cleanup() {
        connection.cancel()
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
                self.stopTimeout()
            default: break
            }
        }
    }
    
    /// receives tcp data and parse it into a message frame
    private func receiveMessage() {
        connection.receive(minimumIncompleteLength: 0x1, maximumLength: 0x2000) { [weak self] data, _, isComplete, error in
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
