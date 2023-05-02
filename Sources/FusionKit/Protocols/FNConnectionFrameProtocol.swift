//
//  FNConnectionFrameProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal protocol FNConnectionFrameProtocol {
    /// create a protocol conform message frame
    /// - Parameter message: generic type which conforms to 'Data' and 'String'
    /// - Returns: message frame as data and optional error
    func create<T: FNConnectionMessage>(message: T) -> (data: Data?, error: Error?)
    
    /// parse a protocol conform message frame
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns parsed message
    func parse(data: Data, _ completion: (FNConnectionMessage?, Error?) -> Void) -> Void
}
