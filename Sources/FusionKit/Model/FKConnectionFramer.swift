//
//  FKConnectionFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import CryptoKit

internal final class FKConnectionFramer: FKConnectionFramerProtocol, @unchecked Sendable {
    private var buffer: DispatchData
    internal func reset() { buffer = .empty }
    
    /// The `FKConnectionFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    
    internal required init(buffer: DispatchData = .empty) {
        self.buffer = buffer
    }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
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
        buffer.append(data.dispatchData)
        guard let length = extractSize() else { return }
        guard buffer.count <= FKConnectionConstants.frame.rawValue else { completion(.failure(FKConnectionError.readBufferOverflow)); return }
        guard buffer.count >= FKConnectionConstants.control.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard let bytes = extractMessage(length: length) else { completion(.failure(FKConnectionError.parsingFailed)); return }
            switch buffer.first {
            case FKConnectionOpcodes.binary.rawValue: completion(.success(bytes))
            case FKConnectionOpcodes.ping.rawValue: completion(.success(UInt16(bytes.count)))
            case FKConnectionOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(.success(result))
            default: completion(.failure(FKConnectionError.unexpectedOpcode)) }
            if buffer.count <= length { reset() } else { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
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
        return Data(size).bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// - Parameter length: the length of the extracting message
    /// - Returns: the extracted message as `Data`
    private func extractMessage(length: UInt32) -> Data? {
        guard buffer.count >= FKConnectionConstants.control.rawValue else { return nil }
        guard length > FKConnectionConstants.control.rawValue else { return Data() }
        return Data(buffer.subdata(in: FKConnectionConstants.control.rawValue..<Int(length)))
    }
}
