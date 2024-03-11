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
    private var connection = FKConnection(host: "measure.weist.org", port: 7878)
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
    private func start(test: TestCase, cancel: Bool = false) {
        let multi = Mulitask()
        Task {
            await multi.start()
        }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Message framer
    private func framer<T: FKConnectionMessage>(message: T) {
        let framer = FKConnectionFramer()
        let message = framer.create(message: message)
        switch message {
        case .success(let data):
            let dispatch = data.withUnsafeBytes { DispatchData(bytes: $0) }
            framer.parse(data: dispatch) { result in
                switch result {
                case .success(let message):
                    if case let message as String = message { XCTAssertEqual(message, uuid); exp.fulfill() }
                    if case let message as Data = message { XCTAssertEqual(message, uuid.data(using: .utf8)); exp.fulfill() }
                case .failure(let error): XCTFail("failed with error: \(error)") }
            }
        case .failure(let error): XCTFail("failed with error: \(error)") }
        wait(for: [exp], timeout: timeout)
    }
}


internal actor Mulitask {
    private var sockets: [FKConnection] = []
    private var counter: Int = .zero
    
    
    func start() {
        for _ in 0...29 {
            sockets.append(FKConnection(host: "mark.weist.org", port: 7878))
        }
        
        for socket in sockets {
            socketTask(connection: socket)
        }
    }
    
    func socketTask(connection: FKConnection) -> Void {
        Task {
            Task { for try await message in connection.messages() { switch message { case .message(let message): break case .bytes(let bytes): counter += bytes.input ?? .zero } } }
            print("Start")
            try await connection.start()
            await connection.send(message: "100000")
            try await Task.sleep(for: .seconds(5.0))
            print(counter)
        }
    }
}
