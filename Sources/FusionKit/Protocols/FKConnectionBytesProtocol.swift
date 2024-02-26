//
//  FKConnectionBytesProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 06.05.23.
//  Copyright © 2023 Vinzenz Weist. All rights reserved.
//

import Foundation

internal protocol FKConnectionBytesProtocol: Sendable {
    /// Input Bytes if available
    var input: Int? { get set }
    
    /// Output Bytes if available
    var output: Int? { get set }
}
