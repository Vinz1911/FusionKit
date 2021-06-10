//
//  NetworkFrame.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal final class NetworkFrame {

    private var buffer: Data
    private let overheadByteCount: Int = Int(0x5)
    private let frameByteCount: Int = Int(UInt32.max)
    
    /// create instance of NetworkFrame
    internal required init() {
        self.buffer = Data()
    }
    
    /// create compliant message conform to 'Message' protocol
    /// - parameters:
    ///     - message: generic type conforms to 'Data' & 'String'
    ///     - completion: completion block, returns error
    /// - returns: message data frame
    internal func create<T: NetworkMessage>(message: T) -> (data: Data?, error: Error?) {
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + overheadByteCount).data)
        frame.append(message.raw)
        guard frame.count <= frameByteCount else { return (nil, NetworkFrameError.writeBufferOverflow) }
        return (frame, nil)
    }
    
    /// parse compliant message which conforms to 'Message' protocol
    /// - parameters:
    ///     - data: the raw data received from connection
    ///     - completion: completion block, returns error
    internal func parse(data: Data, _ completion: (NetworkMessage?) -> Void) -> Error? {
        buffer.append(data)
        guard let messageSize = extractMessageSize() else { return nil }
        guard buffer.count <= frameByteCount else { return NetworkFrameError.readBufferOverflow }
        guard buffer.count >= overheadByteCount, buffer.count >= messageSize else { return nil }
        while buffer.count >= messageSize && messageSize != .zero {
            if buffer.first == NetworkOpcodes.text.rawValue {
                guard let bytes = extractMessage(data: buffer) else { return NetworkFrameError.parsingFailed }
                guard let message = String(bytes: bytes, encoding: .utf8) else { return NetworkFrameError.parsingFailed  }
                completion(message)
            }
            if buffer.first == NetworkOpcodes.binary.rawValue {
                guard let message = extractMessage(data: buffer) else { return NetworkFrameError.parsingFailed }
                completion(message)
            }
            if buffer.count <= messageSize { buffer = Data() } else { buffer = Data(buffer[messageSize...]) }
        }
        return nil
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
