//
//  FKConnectionFramerProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal protocol FKConnectionFramerProtocol {
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: generic Result type returning data and possible error
    func create<T: FKConnectionMessage>(message: T) -> Result<Data, Error>
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    func parse(data: Data, _ completion: (Result<FKConnectionMessage, Error>) -> Void) -> Void
}
