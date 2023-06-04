//
//  FKConnectionFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import CryptoKit

internal final class FKConnectionFramer: FKConnectionFramerProtocol {
    private var buffer = Data()
    internal func reset() { buffer.removeAll() }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: generic Result type returning data and possible error
    internal func create<T: FKConnectionMessage>(message: T) -> Result<Data, Error> {
        guard message.raw.count <= FKConnectionNumbers.frame.rawValue - FKConnectionNumbers.overhead.rawValue else { return .failure(FKConnectionFramerError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FKConnectionNumbers.overhead.rawValue).bigEndianBytes)
        frame.append(Data(SHA256.hash(data: frame.prefix(FKConnectionNumbers.control.rawValue))))
        frame.append(message.raw)
        return .success(frame)
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: Data, _ completion: (Result<FKConnectionMessage, Error>) -> Void) -> Void {
        buffer.append(data)
        guard let length = extractSize() else { return }
        guard buffer.count <= FKConnectionNumbers.frame.rawValue else { completion(.failure(FKConnectionFramerError.readBufferOverflow)); return }
        guard buffer.count >= FKConnectionNumbers.overhead.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard SHA256.hash(data: buffer.prefix(FKConnectionNumbers.control.rawValue)) == extractHash() else { completion(.failure(FKConnectionFramerError.hashMismatch)); return }
            guard let bytes = extractMessage() else { completion(.failure(FKConnectionFramerError.parsingFailed)); return }
            switch buffer.first {
            case FKConnectionOpcodes.binary.rawValue: completion(.success(bytes))
            case FKConnectionOpcodes.ping.rawValue: completion(.success(UInt16(bytes.count)))
            case FKConnectionOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(.success(result))
            default: completion(.failure(FKConnectionFramerError.parsingFailed)) }
            if buffer.count <= length { buffer.removeAll() } else { buffer = Data(buffer[length...]) }
        }
    }
}

// MARK: - Private API Extension -

private extension FKConnectionFramer {
    /// Extract the message hash from the data,
    /// if not possible it returns nil
    /// - Returns: a `SHA256Digest`
    private func extractHash() -> SHA256Digest? {
        guard buffer.count >= FKConnectionNumbers.overhead.rawValue else { return nil }
        let hash = buffer.subdata(in: FKConnectionNumbers.control.rawValue..<FKConnectionNumbers.overhead.rawValue).withUnsafeBytes { $0.load(as: SHA256.Digest.self) }
        return hash
    }
    
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    /// - Returns: the size as `UInt32`
    private func extractSize() -> UInt32? {
        guard buffer.count >= FKConnectionNumbers.overhead.rawValue else { return nil }
        let size = buffer.subdata(in: FKConnectionNumbers.opcode.rawValue..<FKConnectionNumbers.control.rawValue)
        return size.bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// - Returns: the extracted message as `Data`
    private func extractMessage() -> Data? {
        guard buffer.count >= FKConnectionNumbers.overhead.rawValue else { return nil }
        guard let length = extractSize() else { return nil }
        guard length > FKConnectionNumbers.overhead.rawValue else { return Data() }
        return buffer.subdata(in: FKConnectionNumbers.overhead.rawValue..<Int(length))
    }
}
