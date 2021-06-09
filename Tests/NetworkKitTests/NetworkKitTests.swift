import XCTest
@testable import NetworkKit

final class NetworkKitTests: XCTestCase {
    var host: String = "localhost"
    var port: UInt16 = 7878
    var timeout: TimeInterval = 15.0

    func testStringSendAndRespond() {
        let exp = expectation(description: "Wait for test to finish")
        let buffer = "50000"
        var datacount = 0
        let connection = NetworkConnection(host: host, port: port)
        connection.state = { state in
            switch state {
            case .didGetReady:
                connection.send(message: buffer)
            case .didGetCancelled:
                debugPrint("connection closed")
            case .didGetError(let error):
                guard let error = error else { return }
                XCTFail("Failed with Error: \(error)")
            case .didGetMessage(let message):
                if case let message as Data = message {
                    XCTAssertEqual(message.count, Int(buffer))
                    exp.fulfill()
                }
            case .didGetBytes(let bytes):
                guard let byte = bytes.input else { return }
                datacount += byte
                debugPrint("Data Count: \(datacount)")
            }
        }
        connection.openConnection()
        wait(for: [exp], timeout: timeout)
    }
    
    func testDataSendAndRespond() {
        let exp = expectation(description: "Wait for test to finish")
        let buffer = Data(count: 50000)
        var datacount = 0
        let connection = NetworkConnection(host: host, port: port)
        connection.state = { state in
            switch state {
            case .didGetReady:
                connection.send(message: buffer)
            case .didGetCancelled:
                debugPrint("connection closed")
            case .didGetError(let error):
                guard let error = error else { return }
                XCTFail("Failed with Error: \(error)")
            case .didGetMessage(let message):
                if case let message as String = message {
                    XCTAssertEqual(buffer.count, Int(message))
                    exp.fulfill()
                }
            case .didGetBytes(let bytes):
                guard let byte = bytes.output else { return }
                datacount += byte
                debugPrint("Data Count: \(datacount)")
            }
        }
        connection.openConnection()
        wait(for: [exp], timeout: timeout)
    }

    func testMultipleSendDataAndReceiveString() {
        let exp = expectation(description: "Wait for test to finish")
        let buffer = Data(count: 1024)
        var messages = 0
        let sendValue = 100
        var index = 0
        let connection = NetworkConnection(host: host, port: port)
        connection.state = { state in
            switch state {
            case .didGetReady:
                func send() {
                    connection.send(message: buffer) {
                        if index != sendValue {
                            send()
                        }
                        index += 1
                    }
                }
                send()
            case .didGetCancelled:
                debugPrint("connection closed")
            case .didGetError(let error):
                guard let error = error else { return }
                XCTFail("Failed with Error: \(error)")
            case .didGetMessage(let message):
                if case let message as String = message {
                    if messages == sendValue {
                        debugPrint("RECEIVED THIS COUNT: \(message)")
                        debugPrint("Responded Times: \(messages)")
                        exp.fulfill()
                    }
                    messages += 1
                }
            default: break
            }
        }
        connection.openConnection()
        wait(for: [exp], timeout: timeout)
    }
    
    func testMultipleSendStringAndReceiveData() {
        let exp = expectation(description: "Wait for test to finish")
        let buffer = "1024"
        var messages = 0
        let sendValue = 1000
        var index = 0
        let connection = NetworkConnection(host: host, port: port)
        connection.state = { state in
            switch state {
            case .didGetReady:
                func send() {
                    connection.send(message: buffer) {
                        if index != sendValue {
                            send()
                        }
                        index += 1
                    }
                }
                send()
            case .didGetCancelled:
                debugPrint("connection closed")
            case .didGetError(let error):
                guard let error = error else { return }
                XCTFail("Failed with Error: \(error)")
            case .didGetMessage(let message):
                if case let message as Data = message {
                    if messages == sendValue {
                        debugPrint("RECEIVED THIS COUNT: \(message.count)")
                        debugPrint("Responded Times: \(messages)")
                        exp.fulfill()
                    }
                    messages += 1
                }
            default: break
            }
        }
        connection.openConnection()
        wait(for: [exp], timeout: timeout)
    }
}
