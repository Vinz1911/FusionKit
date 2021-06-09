//
//  NetworkFrame.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 25.03.19.
//  Copyright © 2019 Vinzenz Weist. All rights reserved.
//

import Foundation

internal final class NetworkFrame: NetworkFrameProtocol {
    private var buffer = Data()
    private let overheadByteCount: Int = MemoryLayout<UInt32>.size + 1
    private let frameByteCount: Int = Int(UInt32.max)
    private var size: UInt32 {
        guard buffer.count >= overheadByteCount else { return .zero }
        let size = Data(buffer[1...overheadByteCount - 1])
        return size.bigEndian
    }
    private func trim(data: Data) -> Data? {
        guard data.count >= overheadByteCount else { return nil }
        return Data(data[overheadByteCount...Int(size - 1)])
    }
    
    /// create instance of NetworkFrame
    internal required init() { }
    
    
    /// create compliant message conform to 'Message' protocol
    /// - parameters:
    ///     - message: generic type conforms to 'Data' & 'String'
    ///     - completion: completion block, returns error
    /// - returns: message data frame
    internal func create<T: NetworkMessage>(message: T, _ completion: (Error?) -> Void) -> Data {
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + overheadByteCount).data)
        frame.append(message.raw)
        guard frame.count <= frameByteCount else {
            completion(NetworkFrameError.writeBufferOverflow)
            return Data()
        }
        return frame
    }
    
    /// parse compliant message which conforms to 'Message' protocol
    /// - parameters:
    ///     - data: the raw data received from connection
    ///     - completion: completion block, returns error
    internal func parse(data: Data, _ completion: (NetworkMessage?, Error?) -> Void) {
        guard !data.isEmpty else {
            completion(nil, NetworkFrameError.emptyBuffer)
            return
        }
        buffer.append(data)
        let size = self.size
        guard buffer.count <= frameByteCount else {
            completion(nil, NetworkFrameError.readBufferOverflow)
            return
        }
        guard buffer.count >= overheadByteCount, buffer.count >= size else { return }
        while buffer.count >= size && size != .zero {
            if buffer.first == NetworkOpcodes.text.rawValue {
                guard let bytes = trim(data: buffer), let message = String(bytes: bytes, encoding: .utf8) else {
                    completion(nil, NetworkFrameError.parsingFailed)
                    return
                }
                completion(message, nil)
            }
            if buffer.first == NetworkOpcodes.binary.rawValue {
                guard let message = trim(data: buffer) else {
                    completion(nil, NetworkFrameError.parsingFailed)
                    return
                }
                completion(message, nil)
            }
            if buffer.count <= size { buffer = Data() } else { buffer = Data(buffer[size...]) }
        }
    }
}
