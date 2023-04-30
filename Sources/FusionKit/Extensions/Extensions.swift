//
//  Extensions.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - Atomic -

internal class Atomic<Value> {
    private let queue = DispatchQueue(label: UUID().uuidString)
    private var storage: Value
    internal var value: Value { get { queue.sync { storage } } }
    
    /// initialize a atomic value from generic <T>
    /// - Parameter value: init value
    internal init(_ value: Value) { storage = value }
    
    /// change value thread safe
    /// - Parameter transform: the value
    internal func mutate(_ transform: (inout Value) -> Void) { queue.sync { transform(&storage) } }
}

// MARK: - Timer -

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

// MARK: - Data Type Extensions -

internal extension UInt32 {
    /// convert integer to data with bigEndian
    var bigEndianBytes: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

internal extension Int {
    /// minimum size of received bytes
    static var minimum: Int { 0x1 }
    
    /// maximum size of received bytes
    static var maximum: Int { 0x2000 }
}

// internal extensions
internal extension Data {
    /// slice data into chunks
    var chunks: [Data] {
        var size = self.count / 0xFF
        size = Swift.max(size, 0x2000)
        return stride(from: .zero, to: self.count, by: size).map { Data(self[$0..<Swift.min($0 + size, self.count)]) }
    }
    
    /// func to extract integers from data as big endian
    var bigEndian: UInt32 {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { bytes in
            bytes.load(as: UInt32.self)
        })
    }
}
