//
//  NetworkFrame.swift
//  ConnectionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import CryptoKit


internal final class NetworkFrame: NetworkFrameProtocol {
    private var buffer = Atomic<Data>(.init())
    internal func reset() { buffer.mutate { $0 = Data() } }
    
    /// create a protocol conform message frame
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: message frame as data and optional error
    internal func create<T: NetworkMessage>(message: T) -> (data: Data?, error: Error?) {
        guard message.raw.count <= NetworkCounts.frame.rawValue - NetworkCounts.overhead.rawValue else { return (nil, NetworkFrameError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + NetworkCounts.overhead.rawValue).bigEndianBytes)
        frame.append(Data(SHA256.hash(data: frame.prefix(NetworkCounts.control.rawValue))))
        frame.append(message.raw)
        return (frame, nil)
    }
    
    /// parse a protocol conform message frame
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns parsed message
    internal func parse(data: Data, _ completion: (NetworkMessage?, Error?) -> Void) {
        buffer.mutate { $0.append(data) }
        guard let length = extractSize() else { return }
        guard buffer.value.count <= NetworkCounts.frame.rawValue else { completion(nil, NetworkFrameError.readBufferOverflow); return }
        guard buffer.value.count >= NetworkCounts.overhead.rawValue, buffer.count >= length else { return }
        while buffer.value.count >= length && length != .zero {
            guard SHA256.hash(data: buffer.prefix(NetworkCounts.control.rawValue)) == extractHash() else { completion(nil, NetworkFrameError.hashMismatch); return }
            guard let bytes = extractMessage() else { completion(nil, NetworkFrameError.parsingFailed); return }
            switch buffer.value.first {
            case NetworkOpcodes.binary.rawValue: completion(bytes, nil)
            case NetworkOpcodes.ping.rawValue: completion(UInt16(bytes.count), nil)
            case NetworkOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(result, nil)
            default: completion(nil, NetworkFrameError.parsingFailed) }
            if buffer.value.count <= length { buffer.mutate { $0 = Data() } } else { buffer.mutate { $0 = Data(buffer.value[length...]) } }
        }
    }
}

// MARK: - Private API Extension -

private extension NetworkFrame {
    // extract the message hash from the data
    // if not possible it returns nil
    private func extractHash() -> SHA256Digest? {
        guard buffer.count >= NetworkCounts.overhead.rawValue else { return nil }
        let hash = buffer.subdata(in: NetworkCounts.control.rawValue..<NetworkCounts.overhead.rawValue).withUnsafeBytes { $0.load(as: SHA256.Digest.self) }
        return hash
    }
    
    // extract the message frame size from the data
    // if not possible it returns nil
    private func extractSize() -> UInt32? {
        guard buffer.value.count >= NetworkCounts.overhead.rawValue else { return nil }
        let size = buffer.subdata(in: NetworkCounts.opcode.rawValue..<NetworkCounts.control.rawValue)
        return size.bigEndian
    }
    
    // extract the message and remove the overhead
    // if not possible it returns nil
    private func extractMessage() -> Data? {
        guard buffer.count >= NetworkCounts.overhead.rawValue else { return nil }
        guard let length = extractSize() else { return nil }
        guard length > NetworkCounts.overhead.rawValue else { return Data() }
        return buffer.subdata(in: NetworkCounts.overhead.rawValue..<Int(length))
    }
}
