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
    private var connection = FNConnection(host: "atonet.de", port: 7878)
    private var buffer = "50000"
    private let timeout = 10.0
    private let uuid = UUID().uuidString
    private var exp: XCTestExpectation?
    
    /// set up
    override func setUp() {
        super.setUp()
        exp = expectation(description: "wait for test to finish...")
    }
    
    /// start test sending single text message
    func testTextMessage() {
        start(test: .string)
    }
    
    /// start test sending single binary message
    func testBinaryMessage() {
        start(test: .data)
    }
    
    /// start test sending single ping message
    func testPingMessage() {
        start(test: .ping)
    }
    
    /// start test creating and parsing string based message
    func testParsingStringMessage() {
        let message = uuid
        framer(message: message)
    }
    
    /// start test creating and parsing data based message
    func testParsingDataMessage() {
        guard let message = uuid.data(using: .utf8) else { return }
        framer(message: message)
    }
    
    /// start test error description mapping
    func testErrorDescription() {
        XCTAssertEqual(FNConnectionError.missingHost.description, "missing host")
        XCTAssertEqual(FNConnectionError.missingPort.description, "missing port")
        XCTAssertEqual(FNConnectionError.connectionTimeout.description, "connection timeout")
        XCTAssertEqual(FNConnectionError.connectionUnsatisfied.description, "connection path is not satisfied")
        
        XCTAssertEqual(FNConnectionFrameError.hashMismatch.description, "message hash does not match")
        XCTAssertEqual(FNConnectionFrameError.parsingFailed.description, "message parsing failed")
        XCTAssertEqual(FNConnectionFrameError.readBufferOverflow.description, "read buffer overflow")
        XCTAssertEqual(FNConnectionFrameError.writeBufferOverflow.description, "write buffer overflow")
        
        guard let exp else { return }
        exp.fulfill()
        wait(for: [exp], timeout: timeout)
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// create a connection and start
    /// - Parameter test: test case
    private func start(test: TestCase) {
        stateUpdateHandler(connection: connection, test: test)
        connection.receive { [weak self] message, bytes in
            guard let self else { return }
            if let message { handleMessages(message: message) }
        }
        connection.start()
        wait(for: [exp!], timeout: timeout)
    }
    
    /// message framer
    private func framer<T: FNConnectionMessage>(message: T) {
        let framer = FNConnectionFrame()
        let message = framer.create(message: message)
        if let error = message.error { XCTFail("failed with error: \(error)") }
        guard let data = message.data else { XCTFail("failed to get message data"); return }
        
        framer.parse(data: data) { message, error in
            if case let message as String = message { XCTAssertEqual(message, uuid); exp?.fulfill() }
            if case let message as Data = message { XCTAssertEqual(message, uuid.data(using: .utf8)); exp?.fulfill() }
            if let error { XCTFail("failed with error: \(error)") }
        }
        wait(for: [exp!], timeout: timeout)
    }
    
    /// handles test routes for messages
    /// - Parameter message: generic `FNConnectionMessage`
    private func handleMessages(message: FNConnectionMessage) {
        guard let exp else { return }
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
    
    /// state update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: FNConnection, test: TestCase) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if test == .string { connection.send(message: buffer) }
                if test == .data { connection.send(message: Data(count: Int(buffer) ?? 50000)) }
                if test == .ping { connection.send(message: UInt16(buffer) ?? 50000) }
            case .cancelled: break
            case .failed(let error):
                guard let error else { return }
                XCTFail("failed with error: \(error)") }
        }
    }
}
