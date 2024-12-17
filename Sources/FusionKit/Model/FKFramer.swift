//
//  FKFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal final class FKFramer: FKFramerProtocol, @unchecked Sendable {
    private var buffer: DispatchData = .empty
    internal func reset() { buffer = .empty }
    
    /// The `FKFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
    /// - Returns: generic Result type returning data and possible error
    internal func create<T: FKMessage>(message: T) -> Result<Data, Error> {
        guard message.raw.count <= FKConstants.frame.rawValue - FKConstants.control.rawValue else { return .failure(FKError.writeBufferOverflow) }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FKConstants.control.rawValue).bigEndianBytes)
        frame.append(message.raw)
        return .success(frame)
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: DispatchData, _ completion: (Result<FKMessage, Error>) -> Void) -> Void {
        buffer.append(data)
        guard let length = extractSize() else { return }
        guard buffer.count <= FKConstants.frame.rawValue else { completion(.failure(FKError.readBufferOverflow)); return }
        guard buffer.count >= FKConstants.control.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard let bytes = extractMessage(length: length) else { completion(.failure(FKError.parsingFailed)); return }
            switch buffer.first {
            case FKOpcodes.binary.rawValue: completion(.success(bytes))
            case FKOpcodes.ping.rawValue: completion(.success(UInt16(bytes.count)))
            case FKOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { return }; completion(.success(result))
            default: completion(.failure(FKError.unexpectedOpcode)) }
            if buffer.count <= length { reset() } else { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
        }
    }
}

// MARK: - Private API Extension -

private extension FKFramer {
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    ///
    /// - Returns: the size as `UInt32`
    private func extractSize() -> UInt32? {
        guard buffer.count >= FKConstants.control.rawValue else { return nil }
        let size = buffer.subdata(in: FKConstants.opcode.rawValue..<FKConstants.control.rawValue)
        return Data(size).bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// 
    /// - Parameter length: the length of the extracting message
    /// - Returns: the extracted message as `Data`
    private func extractMessage(length: UInt32) -> Data? {
        guard buffer.count >= FKConstants.control.rawValue else { return nil }
        guard length > FKConstants.control.rawValue else { return Data() }
        return Data(buffer.subdata(in: FKConstants.control.rawValue..<Int(length)))
    }
}
