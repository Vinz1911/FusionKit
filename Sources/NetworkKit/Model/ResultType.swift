//
//  ResultType.swift
//  FastSocketKit
//
//  Created by Vinzenz Weist on 09.06.21.
//

import Foundation

/// result type for input & output bytes
public struct NetworkBytes {
    public var input: Int?
    public var output: Int?
}

/// NetworkKit result type
public enum NetworkConnectionResult {
    case didGetReady
    case didGetCancelled
    case didGetError(Error?)
    case didGetMessage(NetworkMessage)
    case didGetBytes(NetworkBytes)
}

/// peer connection result type
internal enum NetworkConnectionHandlerResult {
    case didGetReady
    case didGetCancelled
    case didGetError(Error?)
    case didGetData(Data)
    case didGetBytes(NetworkBytes)
}
