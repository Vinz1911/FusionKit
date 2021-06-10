//
//  NetworkKitTestMultipleMessage.swift.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import NetworkKit

private enum TestCase {
    case string
    case data
}

class NetworkKitTestMultiMessage: XCTestCase {
    
    private var connection = NetworkConnection(host: "network-co.de", port: 7878)
    private var buffer = "1000"
    private let timeout = 15.0
    private var index = Int()
    private var receiveCount = Int()
    private let sendCount = 100
    private var cases: TestCase? = nil
    private var exp: XCTestExpectation?
    
    /// set up
    override func setUp() {
        super.setUp()
        exp = expectation(description: "wait for test to finish...")
    }
    
    /// start test sending multi text message
    func testTextMessage() {
        cases = .string
        stateUpdateHandler(connection: connection)
        connection.start()
        wait(for: [exp!], timeout: timeout)
    }
    
    /// start test sending multi binary message
    func testBinaryMessage() {
        cases = .data
        stateUpdateHandler(connection: connection)
        connection.start()
        wait(for: [exp!], timeout: timeout)
    }
}

// MARK: - Private API Extension

private extension NetworkKitTestMultiMessage {
    
    /// sends specific amount of messages
    /// - Parameter message: conforms to 'Data' & 'String'
    private func sendMessages<T: NetworkMessage>(message: T) {
        self.connection.send(message: message) { [weak self] in
            guard let self = self else { return }
            if self.index != self.sendCount { self.sendMessages(message: message) }
            self.index += 1
        }
    }
    
    /// state update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: NetworkConnection) {
        connection.stateUpdateHandler = { state in
            switch state {
            case .didGetReady:
                if self.cases == .string {
                    guard self.index < self.sendCount else { return }
                    self.sendMessages(message: self.buffer)
                }
                
                if self.cases == .data {
                    guard self.index < self.sendCount else { return }
                    self.sendMessages(message: Data(count: Int(self.buffer)!))
                }
                
            case .didGetMessage(_):
                if self.receiveCount == self.sendCount {
                    XCTAssertEqual(self.receiveCount, self.sendCount)
                    connection.cancel()
                    self.exp?.fulfill()
                }
                self.receiveCount += 1
                
            case .didGetError(let error):
                guard let error = error else { return }
                XCTFail("failed with error: \(error)")
    
            default: break
            }
        }
    }
}
