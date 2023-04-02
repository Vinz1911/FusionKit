import XCTest
@testable import FusionKit

private enum TestCase {
    case string; case data; case ping
}

class FusionKitTests: XCTestCase {
    private var connection = FNConnection(host: "127.0.0.1", port: 7878)
    private var buffer = "50000"
    private let timeout = 10.0
    private var cases: TestCase? = nil
    private var exp: XCTestExpectation?
    
    /// set up
    override func setUp() {
        super.setUp()
        exp = expectation(description: "wait for test to finish...")
    }
    
    /// start test sending single text message
    func testTextMessage() {
        cases = .string; start()
    }
    
    /// start test sending single binary message
    func testBinaryMessage() {
        cases = .data; start()
    }
    
    /// start test sending single ping message
    func testPingMessage() {
        cases = .ping; start()
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// create a connection and start
    private func start() {
        stateUpdateHandler(connection: connection)
        connection.start()
        wait(for: [exp!], timeout: timeout)
    }
    
    /// state update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: FNConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                if self.cases == .string { connection.send(message: self.buffer) }
                if self.cases == .data { connection.send(message: Data(count: Int(self.buffer)!)) }
                if self.cases == .ping { connection.send(message: UInt16(self.buffer)!) }
                
            case .message(let message):
                if case let message as UInt16 = message {
                    XCTAssertEqual(message, UInt16(self.buffer))
                    connection.cancel()
                    self.exp?.fulfill()
                }
                if case let message as Data = message {
                    XCTAssertEqual(message.count, Int(self.buffer))
                    connection.cancel()
                    self.exp?.fulfill()
                }
                if case let message as String = message {
                    XCTAssertEqual(message, self.buffer)
                    connection.cancel()
                    self.exp?.fulfill()
                }
                
            case .failed(let error):
                guard let error = error else { return }
                XCTFail("failed with error: \(error)")

            default: break }
        }
    }
}
