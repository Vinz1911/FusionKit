//
//  NetworkFrame.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal struct NetworkFrame: NetworkFrameProtocol {

    private var buffer: Data = Data()
    private let overheadByteCount: Int = Int(0x5)
    private let frameByteCount: Int = Int(UInt32.max)

    /// create compliant message conform to 'NetworkMessage' protocol
    /// - Parameters:
    ///   - message: generic type conforms to 'Data' and 'String'
    ///   - completion: completion block, returns error
    /// - Returns: message data frame
    internal func create<T: NetworkMessage>(message: T) -> (data: Data?, error: Error?) {
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + overheadByteCount).data)
        frame.append(message.raw)
        guard frame.count <= frameByteCount else { return (nil, NetworkFrameError.writeBufferOverflow) }
        return (frame, nil)
    }
    
    /// parse a protocol conform message frame
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns parsed message
    /// - Returns: optional error
    internal mutating func parse(data: Data, _ completion: (NetworkMessage?, Error?) -> Void) {
        buffer.append(data)
        guard let messageSize = extractMessageSize() else { return }
        guard buffer.count <= frameByteCount else { completion(nil, NetworkFrameError.readBufferOverflow); return }
        guard buffer.count >= overheadByteCount, buffer.count >= messageSize else { return }
        while buffer.count >= messageSize && messageSize != .zero {
            if buffer.first == NetworkOpcodes.text.rawValue {
                guard let bytes = extractMessage(data: buffer) else { completion(nil, NetworkFrameError.parsingFailed); return }
                guard let message = String(bytes: bytes, encoding: .utf8) else { completion(nil, NetworkFrameError.parsingFailed); return }
                completion(message, nil)
            }
            if buffer.first == NetworkOpcodes.binary.rawValue {
                guard let message = extractMessage(data: buffer) else { completion(nil, NetworkFrameError.parsingFailed); return }
                completion(message, nil)
            }
            if buffer.count <= messageSize { buffer = Data() } else { buffer = Data(buffer[messageSize...]) }
        }
    }
}

// MARK: - Private API Extension

private extension NetworkFrame {
    
    // extract the message frame size from the data
    // if not possible it returns nil
    private func extractMessageSize() -> UInt32? {
        guard buffer.count >= overheadByteCount else { return nil }
        let size = Data(buffer[1...overheadByteCount - 1])
        return size.bigEndian
    }
    
    // extract the message and remove the overhead
    // if not possible it returns nil
    private func extractMessage(data: Data) -> Data? {
        guard data.count >= overheadByteCount else { return nil }
        guard let messageSize = extractMessageSize() else { return nil }
        return Data(data[overheadByteCount...Int(messageSize - 1)])
    }
}
