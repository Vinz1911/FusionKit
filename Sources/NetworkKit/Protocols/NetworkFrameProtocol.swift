//
//  NetworkFrameProtocol.swift
//  NetworkKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//
import Foundation

internal protocol NetworkFrameProtocol {
    
    init()
    /// create compliant message conform to 'Message' protocol
    /// - parameters:
    ///     - message: generic type conforms to 'Data' & 'String'
    ///     - completion: completion block, returns error
    /// - returns: message data frame
    func create<T: NetworkMessage>(message: T, _ completion: (Error?) -> Void) -> Data
    
    /// parse compliant message which conforms to 'Message' protocol
    /// - parameters:
    ///     - data: the raw data received from connection
    ///     - completion: completion block, returns error
    func parse(data: Data, _ completion: (NetworkMessage?, Error?) -> Void)
}
