//
//  Extensions.swift
//  NetworKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//
import Foundation
import Network

internal extension Timer {
    
    /// create a timeout
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

internal extension UInt32 {
    /// convert integer to data with bigEndian
    var bigEndianBytes: Data {
        withUnsafeBytes(of: self.bigEndian) { bytes in Data(bytes) }
    }
}

internal extension Int {
    static var minimum: Int { 0x1 }
    static var maximum: Int { 0x2000 }
}

// internal extensions
internal extension Data {
    /// slice data into chunks
    var chunks: [Data] {
        var size = self.count / 0xFF
        size = Swift.max(size, 0x2000)
        return stride(from: .zero, to: self.count, by: size).map { count in
            Data(self[count..<Swift.min(count + size, self.count)])
        }
    }
    /// func to extract integers from data as big endian
    var bigEndian: UInt32 {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { bytes in
            bytes.load(as: UInt32.self)
        })
    }
}
