//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import FusionKit

private enum TestCase {
    case string
    case data
    case ping
}

class FusionKitTests: XCTestCase {
    private var connection = FKConnection(host: "localhost", port: 7878)
    private var buffer = "50000"
    private let timeout = 10.0
    private let uuid = UUID().uuidString
    private var exp = XCTestExpectation(description: "wait for test to finish...")
    
    /// Set up
    override func setUp() {
        super.setUp()
    }
    
    /// Start test sending single text message
    func testTextMessage() {
        start(test: .string)
    }
    
    /// Start test sending single binary message
    func testBinaryMessage() {
        start(test: .data)
    }
    
    /// Start test sending single ping message
    func testPingMessage() {
        start(test: .ping)
    }
    
    /// Start test creating and parsing string based message
    func testParsingStringMessage() {
        let message = uuid
        framer(message: message)
    }
    
    /// Start test creating and parsing data based message
    func testParsingDataMessage() {
        guard let message = uuid.data(using: .utf8) else { return }
        framer(message: message)
    }
    
    /// Start test error description mapping
    func testErrorDescription() {
        XCTAssertEqual(FKConnectionError.missingHost.description, "missing host")
        XCTAssertEqual(FKConnectionError.missingPort.description, "missing port")
        XCTAssertEqual(FKConnectionError.connectionTimeout.description, "connection timeout")
        XCTAssertEqual(FKConnectionError.connectionUnsatisfied.description, "connection path is not satisfied")
        XCTAssertEqual(FKConnectionError.hashMismatch.description, "message hash does not match")
        XCTAssertEqual(FKConnectionError.parsingFailed.description, "message parsing failed")
        XCTAssertEqual(FKConnectionError.readBufferOverflow.description, "read buffer overflow")
        XCTAssertEqual(FKConnectionError.writeBufferOverflow.description, "write buffer overflow")
        
        exp.fulfill()
        wait(for: [exp], timeout: timeout)
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Create a connection and start
    /// - Parameter test: test case
    private func start(test: TestCase) {
        stateUpdateHandler(connection: connection, test: test)
        connection.receive { [weak self] message, bytes in
            guard let self else { return }
            if let message { handleMessages(message: message) }
        }
        connection.start()
        wait(for: [exp], timeout: timeout)
    }
    
    /// Message framer
    private func framer<T: FKConnectionMessage>(message: T) {
        let framer = FKConnectionFramer()
        let message = framer.create(message: message)
        switch message {
        case .success(let data):
            framer.parse(data: data) { result in
                switch result {
                case .success(let message):
                    if case let message as String = message { XCTAssertEqual(message, uuid); exp.fulfill() }
                    if case let message as Data = message { XCTAssertEqual(message, uuid.data(using: .utf8)); exp.fulfill() }
                case .failure(let error): XCTFail("failed with error: \(error)") }
            }
        case .failure(let error): XCTFail("failed with error: \(error)") }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Handles test routes for messages
    /// - Parameter message: generic `FKConnectionMessage`
    private func handleMessages(message: FKConnectionMessage) {
        if case let message as UInt16 = message {
            XCTAssertEqual(message, UInt16(buffer))
            connection.cancel()
            exp.fulfill()
        }
        if case let message as Data = message {
            XCTAssertEqual(message.count, Int(buffer))
            connection.cancel()
            exp.fulfill()
        }
        if case let message as String = message {
            XCTAssertEqual(message, buffer)
            connection.cancel()
            exp.fulfill()
        }
    }
    
    /// State update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: FKConnection, test: TestCase) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if test == .string { connection.send(message: buffer) }
                if test == .data { connection.send(message: Data(count: Int(buffer)!)) }
                if test == .ping { connection.send(message: UInt16(buffer)!) }
            case .cancelled: break
            case .failed(let error):
                guard let error else { return }
                XCTFail("failed with error: \(error)") }
        }
    }
}
