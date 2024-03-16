//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import FusionKit

private enum FusionKitTypes {
    case string; case data; case ping
}

class FusionKitTests: XCTestCase {
    private var connection = FKConnection(host: "mark.weist.org", port: 7878)
    private let framer = FKConnectionFramer()
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
        start(type: .string)
    }
    
    /// Start test sending single binary message
    func testBinaryMessage() {
        start(type: .data)
    }
    
    /// Start test sending single ping message
    func testPingMessage() {
        start(type: .ping)
    }
    
    /// Start test sending and cancel
    func testCancel() {
        start(type: nil, cancel: true)
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
        XCTAssertEqual(FKConnectionError.parsingFailed.description, "message parsing failed")
        XCTAssertEqual(FKConnectionError.readBufferOverflow.description, "read buffer overflow")
        XCTAssertEqual(FKConnectionError.writeBufferOverflow.description, "write buffer overflow")
        XCTAssertEqual(FKConnectionError.unexpectedOpcode.description, "unexpected opcode")
        
        exp.fulfill()
        wait(for: [exp], timeout: timeout)
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Start test base on `FusionKitTypes`
    /// - Parameters:
    ///   - type: the `FusionKitTypes`
    ///   - cancel: bool to cancel
    private func start(type: FusionKitTypes?, cancel: Bool = false) {
        Task {
            Task { do { try await receive() } catch { print("[Fusion]: \(error)") } }
            if cancel { connection.cancel(); exp.fulfill(); return }
            while connection.state != .running { if connection.state == .running { break } }
            guard let type else { return }
            switch type {
            case .string: await connection.send(message: buffer)
            case .data: await connection.send(message: Data(count: Int(buffer) ?? .zero))
            case .ping: await connection.send(message: UInt16(buffer) ?? .zero) }
        }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Receive Task
    private func receive() async throws -> Void {
        for try await result in connection.receive() {
            if case .message(let message) = result {
                if case let message as String = message { XCTAssertEqual(message, buffer); exp.fulfill() }
                if case let message as Data = message { XCTAssertEqual(message.count, Int(buffer)); exp.fulfill() }
                if case let message as UInt16 = message { XCTAssertEqual(message, UInt16(buffer)); exp.fulfill() }
                connection.cancel()
            }
        }
    }
    
    /// Message create
    private func framer<T: FKConnectionMessage>(message: T) {
        let message = framer.create(message: message)
        switch message {
        case .success(let data): let dispatch = data.withUnsafeBytes { DispatchData(bytes: $0) }; parser(data: dispatch)
        case .failure(let error): XCTFail("failed with error: \(error)") }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Message parse
    private func parser(data: DispatchData) {
        framer.parse(data: data) { result in
            if case .failure(let error) = result { XCTFail("failed with error: \(error)") }
            if case .success(let message) = result {
                if case let message as String = message { XCTAssertEqual(message, uuid); exp.fulfill() }
                if case let message as Data = message { XCTAssertEqual(message, uuid.data(using: .utf8)); exp.fulfill() }
            }
        }
    }
}
