//
//  FNConnectionFrame.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import CryptoKit

internal final class FNConnectionFrame: FNConnectionFrameProtocol {
    private var buffer = Data()
    internal func reset() { buffer.removeAll() }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: message frame as data and optional error
    internal func create<T: FNConnectionMessage>(message: T) -> (data: Data?, error: Error?) {
        guard message.raw.count <= FNConnectionCounts.frame.rawValue - FNConnectionCounts.overhead.rawValue else { return (nil, FNConnectionFrameError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FNConnectionCounts.overhead.rawValue).bigEndianBytes)
        frame.append(Data(SHA256.hash(data: frame.prefix(FNConnectionCounts.control.rawValue))))
        frame.append(message.raw)
        return (frame, nil)
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns parsed message
    internal func parse(data: Data, _ completion: (FNConnectionMessage?, Error?) -> Void) -> Void {
        buffer.append(data)
        guard let length = extractSize() else { return }
        guard buffer.count <= FNConnectionCounts.frame.rawValue else { completion(nil, FNConnectionFrameError.readBufferOverflow); return }
        guard buffer.count >= FNConnectionCounts.overhead.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard SHA256.hash(data: buffer.prefix(FNConnectionCounts.control.rawValue)) == extractHash() else { completion(nil, FNConnectionFrameError.hashMismatch); return }
            guard let bytes = extractMessage() else { completion(nil, FNConnectionFrameError.parsingFailed); return }
            switch buffer.first {
            case FNConnectionOpcodes.binary.rawValue: completion(bytes, nil)
            case FNConnectionOpcodes.ping.rawValue: completion(UInt16(bytes.count), nil)
            case FNConnectionOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(result, nil)
            default: completion(nil, FNConnectionFrameError.parsingFailed) }
            if buffer.count <= length { buffer.removeAll() } else { buffer = Data(buffer[length...]) }
        }
    }
}

// MARK: - Private API Extension -

private extension FNConnectionFrame {
    /// Extract the message hash from the data,
    /// if not possible it returns nil
    /// - Returns: a `SHA256Digest`
    private func extractHash() -> SHA256Digest? {
        guard buffer.count >= FNConnectionCounts.overhead.rawValue else { return nil }
        let hash = buffer.subdata(in: FNConnectionCounts.control.rawValue..<FNConnectionCounts.overhead.rawValue).withUnsafeBytes { $0.load(as: SHA256.Digest.self) }
        return hash
    }
    
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    /// - Returns: the size as `UInt32`
    private func extractSize() -> UInt32? {
        guard buffer.count >= FNConnectionCounts.overhead.rawValue else { return nil }
        let size = buffer.subdata(in: FNConnectionCounts.opcode.rawValue..<FNConnectionCounts.control.rawValue)
        return size.bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// - Returns: the extracted message as `Data`
    private func extractMessage() -> Data? {
        guard buffer.count >= FNConnectionCounts.overhead.rawValue else { return nil }
        guard let length = extractSize() else { return nil }
        guard length > FNConnectionCounts.overhead.rawValue else { return Data() }
        return buffer.subdata(in: FNConnectionCounts.overhead.rawValue..<Int(length))
    }
}
