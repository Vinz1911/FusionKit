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
    private var buffer = Data()
    private let overheadByteCount = Int(0x25)
    private let frameByteCount = Int(UInt32.max)
    internal func reset() { buffer = Data() }
    
    /// create a protocol conform message frame
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: message frame as data and optional error
    internal func create<T: NetworkMessage>(message: T) -> (data: Data?, error: Error?) {
        guard message.raw.count <= frameByteCount - overheadByteCount else { return (nil, NetworkFrameError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + overheadByteCount).bigEndianBytes)
        frame.append(Data(SHA256.hash(data: frame.prefix(0x5))))
        frame.append(message.raw)
        return (frame, nil)
    }
    
    /// parse a protocol conform message frame
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns parsed message
    internal func parse(data: Data, _ completion: (NetworkMessage?, Error?) -> Void) {
        buffer.append(data)
        guard let length = extractSize() else { return }
        guard buffer.count <= frameByteCount else { completion(nil, NetworkFrameError.readBufferOverflow); return }
        guard buffer.count >= overheadByteCount, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard SHA256.hash(data: buffer.prefix(0x5)) == extractHash() else { completion(nil, NetworkFrameError.hashMismatch); return }
            guard let bytes = extractMessage() else { completion(nil, NetworkFrameError.parsingFailed); return }
            switch buffer.first {
            case NetworkOpcodes.binary.rawValue: completion(bytes, nil)
            case NetworkOpcodes.ping.rawValue: completion(UInt16(bytes.count), nil)
            case NetworkOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(result, nil)
            default: completion(nil, NetworkFrameError.parsingFailed) }
            if buffer.count <= length { buffer = Data() } else { buffer = buffer[length...] }
        }
    }
}

// MARK: - Private API Extension -

private extension NetworkFrame {
    // extract the message hash from the data
    // if not possible it returns nil
    private func extractHash() -> SHA256Digest? {
        guard buffer.count >= overheadByteCount else { return nil }
        let hash = buffer.subdata(in: 0x5..<0x25).withUnsafeBytes { $0.load(as: SHA256.Digest.self) }
        return hash
    }
    
    // extract the message frame size from the data
    // if not possible it returns nil
    private func extractSize() -> UInt32? {
        guard buffer.count >= overheadByteCount else { return nil }
        let size = buffer.subdata(in: 0x1..<0x6)
        return size.bigEndian
    }
    
    // extract the message and remove the overhead
    // if not possible it returns nil
    private func extractMessage() -> Data? {
        guard buffer.count >= overheadByteCount else { return nil }
        guard let length = extractSize() else { return nil }
        guard length > overheadByteCount else { return Data() }
        return buffer.subdata(in: overheadByteCount..<Int(length))
    }
}
