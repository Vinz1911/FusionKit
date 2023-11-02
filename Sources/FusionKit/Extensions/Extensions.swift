//
//  Extensions.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - Timer -

internal extension Timer {
    /// Create a timeout
    ///
    /// - Parameters:
    ///   - after: executed after given time
    ///   - completion: completion
    /// - Returns: a source timer
    static func timeout(after: TimeInterval = 3.0, _ completion: @escaping () -> Void) -> DispatchSourceTimer {
        let dispatchTimer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue(label: UUID().uuidString))
        dispatchTimer.setEventHandler(handler: completion)
        dispatchTimer.schedule(deadline: .now() + after, repeating: .never)
        dispatchTimer.resume()
        return dispatchTimer
    }
}

// MARK: - Type Extensions -

internal extension UInt32 {
    /// Convert integer to data with bigEndian
    var bigEndianBytes: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

internal extension Int {
    /// Minimum size of received bytes
    static var minimum: Int { 0x1 }
    
    /// Maximum size of received bytes
    static var maximum: Int { 0x8000 }
}

internal extension Data {
    /// Slice data into chunks
    var chunks: [Data] {
        let size = Int.maximum
        return stride(from: .zero, to: count, by: size).map { subdata(in: $0..<(count - $0 > size ? $0 + size : count)) }
    }
    
    /// Extract integers from data as big endian
    var bigEndian: UInt32 {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
    
    /// Convert `Data` into `DispatchData`
    var dispatchData: DispatchData {
        return withUnsafeBytes { DispatchData(bytes: $0) }
    }
}
