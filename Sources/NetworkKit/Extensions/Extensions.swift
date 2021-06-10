//
//  Extensions.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//
import Foundation
import Network

internal extension UInt32 {
    /// convert integer to data with bigEndian
    var data: Data {
        withUnsafeBytes(of: self.bigEndian) { bytes in Data(bytes) }
    }
}

// internal extensions
internal extension Data {
    /// slice data into chunks
    var chunk: [Data] {
        var size = self.count / 0xFF
        if size <= 0x2000 { size = 0x2000 }
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
