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

class FusionKitTests: XCTestCase, @unchecked Sendable {
    private var connection = try? FKConnection(host: "de0.weist.org", port: 7878)
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
    
    /// Start test sending and cancel
    func testCancel() {
        start(test: .data, cancel: true)
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
        XCTAssertEqual(FKError.connectionTimeout.description, "connection timeout")
        XCTAssertEqual(FKError.parsingFailed.description, "message parsing failed")
        XCTAssertEqual(FKError.readBufferOverflow.description, "read buffer overflow")
        XCTAssertEqual(FKError.writeBufferOverflow.description, "write buffer overflow")
        XCTAssertEqual(FKError.unexpectedOpcode.description, "unexpected opcode")
        
        do { _ = try FKConnection(host: "", port: 7878) } catch {
            guard let error = error as? FKError else { return }
            XCTAssert(error.description == "missing host")
        }
        do { _ = try FKConnection(host: "de0.weist.org", port: 0) } catch {
            guard let error = error as? FKError else { return }
            XCTAssert(error.description == "missing port")
        }
        
        exp.fulfill()
        wait(for: [exp], timeout: timeout)
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Create a connection and start
    /// - Parameter test: test case
    private func start(test: TestCase, cancel: Bool = false) {
        guard let connection else { return }
        stateUpdateHandler(connection: connection, test: test)
        connection.receive { [weak self] message, bytes in
            guard let self else { return }
            if cancel { connection.cancel() }
            if let message { assertion(message: message) }
        }
        connection.start()
        wait(for: [exp], timeout: timeout)
    }
    
    /// Message framer
    private func framer<T: FKMessage>(message: T) {
        let framer = FKFramer()
        let message = framer.create(message: message)
        
        if case let .success(data) = message {
            let dispatch = data.withUnsafeBytes { DispatchData(bytes: $0) }
            framer.parse(data: dispatch) { result in
                if case let .success(message) = result {
                    if case let message as String = message { XCTAssertEqual(message, uuid); exp.fulfill() }
                    if case let message as Data = message { XCTAssertEqual(message, uuid.data(using: .utf8)); exp.fulfill() }
                }
                if case let .failure(error) = result { XCTFail("failed with error: \(error)") }
            }
        }
        if case let .failure(error) = message { XCTFail("failed with error: \(error)") }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Handles test routes for messages
    /// - Parameter message: generic `FKMessage`
    private func assertion(message: FKMessage) {
        guard let connection else { return }
        if case let message as UInt16 = message {
            XCTAssertEqual(message, UInt16(buffer))
            connection.cancel(); exp.fulfill()
        }
        if case let message as Data = message {
            XCTAssertEqual(message.count, Int(buffer))
            connection.cancel(); exp.fulfill()
        }
        if case let message as String = message {
            XCTAssertEqual(message, buffer)
            connection.cancel(); exp.fulfill()
        }
    }
    
    /// State update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: FKConnection, test: TestCase) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                if test == .string { connection.send(message: buffer) }
                if test == .data { connection.send(message: Data(count: Int(buffer)!)) }
                if test == .ping { connection.send(message: UInt16(buffer)!) }
            }
            if case .cancelled = state { exp.fulfill() }
            if case let .failed(error) = state { guard let error else { return }; XCTFail("failed with error: \(error)") }
        }
    }
}
