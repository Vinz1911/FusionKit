# FusionKit

`FusionKit` is a library which implements the `Fusion Framing Protocol (FFP)`. 
The `Fusion Framing Protocol (FFP)` is proprietary networking protocol which uses a small and lightweight header with a performance as fast as raw tcp performance. Built directly on top of Apples `Network.framework` with support for plain tcp and tls encrypted connections. The implementation for the host is [Fusion](https://github.com/Vinz1911/fusion) written in golang with awesome concurrency support to ensure maximum performance.

# Overview
| Swift Version                                                                                                | License                                                                                                                                              | Coverage                                                                                                                                              |
|--------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| [![Swift 5.8](https://img.shields.io/badge/Swift-5.8-orange.svg?logo=swift&style=flat)](https://swift.org)   | [![License](https://img.shields.io/badge/license-GPLv3-blue.svg?longCache=true&style=flat)](https://github.com/Vinz1911/FusionKit/blob/main/LICENSE) | [![codecov](https://codecov.io/github/Vinz1911/FusionKit/branch/main/graph/badge.svg?token=EE3S0BOINS)](https://codecov.io/github/Vinz1911/FusionKit) |
| [![Swift 5.8](https://img.shields.io/badge/SPM-Support-orange.svg?logo=swift&style=flat)](https://swift.org) |                                                                                                                                                      |                                                                                                                                                       |

## Installation:
### Swift Packages
[Swift Package Manager](https://developer.apple.com/documentation/xcode/swift-packages). Just add this repo to your project.

```swift
// ...
dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Vinz1911/FusionKit.git", .exact("7.1.0")),
],
// ...
```

## Import:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FKConnection(host: "example.com", port: 8080)

// support for NWParameters, tls example:
let connection = FKConnection(host: "example.com", port: 8080, parameters: .tls)

// ...
```

## State Handler:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FKConnection(host: "example.com", port: 8080)

// state update handler
connection.stateUpdateHandler = { state in
    switch state {
    case .ready:
        // connection is ready
    case .cancelled:
        // connection is cancelled
    case .failed(let error):
        // connection failed with error
    }
}

// start connection
connection.start()
```

## Send Messages:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FKConnection(host: "example.com", port: 8080)

// the framework accepts generic data types
// send strings
connection.send(message: "Hello World!")

// send data
connection.send(message: Data(count: 100))

// send ping
connection.send(message: UInt16.max)
```

## Parse Message:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FKConnection(host: "example.com", port: 8080)

// read incoming messages and transmitted bytes count
connection.receive { message, bytes in    
    // Data Message
    if case let message as Data = message { }
    
    // String Message
    if case let message as String = message { }
    
    // UInt16 Message
    if case let message as UInt16 = message { }
    
    // Input Bytes
    if let input = bytes.input { }
    
    // Output Bytes
    if let output = bytes.output { }
}

connection.send(message: "Hello World! 👻")
```

## Author:
👨🏼‍💻 [Vinzenz Weist](https://github.com/Vinz1911)
