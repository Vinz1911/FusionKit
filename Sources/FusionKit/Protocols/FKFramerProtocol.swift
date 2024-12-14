//
//  FKFramerProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal protocol FKFramerProtocol: Sendable {
    /// The `FKFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: generic Result type returning data and possible error
    func create<T: FKMessage>(message: T) -> Result<Data, Error>
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    func parse(data: DispatchData, _ completion: (Result<FKMessage, Error>) -> Void) -> Void
}
