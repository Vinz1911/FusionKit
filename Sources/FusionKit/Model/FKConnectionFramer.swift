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
        guard message.raw.count <= FKConnectionConstants.frame.rawValue - FKConnectionConstants.control.rawValue else { return .failure(FKConnectionError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FKConnectionConstants.control.rawValue).bigEndianBytes)
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
        guard buffer.count <= FKConnectionConstants.frame.rawValue else { completion(.failure(FKConnectionError.readBufferOverflow)); return }
        guard buffer.count >= FKConnectionConstants.control.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard let bytes = extractMessage() else { completion(.failure(FKConnectionError.parsingFailed)); return }
            switch buffer.first {
            case FKConnectionOpcodes.binary.rawValue: completion(.success(bytes))
            case FKConnectionOpcodes.ping.rawValue: completion(.success(UInt16(bytes.count)))
            case FKConnectionOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(.success(result))
            default: completion(.failure(FKConnectionError.parsingFailed)) }
            if buffer.count <= length { buffer.removeAll() } else { buffer = Data(buffer[length...]) }
        }
    }
}

// MARK: - Private API Extension -

private extension FKConnectionFramer {
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    /// - Returns: the size as `UInt32`
    private func extractSize() -> UInt32? {
        guard buffer.count >= FKConnectionConstants.control.rawValue else { return nil }
        let size = buffer.subdata(in: FKConnectionConstants.opcode.rawValue..<FKConnectionConstants.control.rawValue)
        return size.bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// - Returns: the extracted message as `Data`
    private func extractMessage() -> Data? {
        guard buffer.count >= FKConnectionConstants.control.rawValue else { return nil }
        guard let length = extractSize() else { return nil }
        guard length > FKConnectionConstants.control.rawValue else { return Data() }
        return buffer.subdata(in: FKConnectionConstants.control.rawValue..<Int(length))
    }
}
