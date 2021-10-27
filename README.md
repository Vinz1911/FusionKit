# ConnectionKit 🔀

`ConnectionKit` is a library which implements the `NWC-Protocol`. The `NWC-Protocol` is proprietary networking protocol which uses a small and lightweight header with a performance as fast as raw tcp performance. Built directly on top of Apples `Network.framework` with support for plain tcp and tls encrypted connections. The implementation for the host is [Network-GO](https://github.com/Vinz1911/network-go) written in golang with awesome concurrency support to ensure maximum performance.

## License:
[![License](https://img.shields.io/badge/license-GPLv3-blue.svg?longCache=true&style=flat)](https://github.com/Vinz1911/ConnectionKit/blob/main/LICENSE)

## Swift Version:
[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?logo=swift&style=flat)](https://swift.org) [![Swift 5.5](https://img.shields.io/badge/SPM-Support-orange.svg?logo=swift&style=flat)](https://swift.org)

## Installation:
### Swift Packages
[Swift Package Manager](https://developer.apple.com/documentation/swift_packages). Just add this repo to your project.

## Import:
```swift
// import the Framework
import ConnectionKit

// create a new connection
let connection = NetworkConnection(host: "example.com", port: 8080)

// support for NWParameters, tls example:
let connection = NetworkConnection(host: "example.com", port: 8080, parameters: .tls)

// ...
```

## Callback:
```swift
// import the Framework
import ConnectionKit

// create a new connection
let connection = NetworkConnection(host: "example.com", port: 8080)

// state update handler
connection.stateUpdateHandler = { state in
    switch state {
    case .ready:
        // connection is ready
    case .cancelled:
        // connection is cancelled
    case .failed(let error):
        // connection failed with error
    case .message(let message):
        // connection received message
    case .bytes(let bytes):
        // connection send/received bytes
    }
}

// start connection
connection.start()
```

## Send Messages:
```swift
// import the Framework
import ConnectionKit

// create a new connection
let connection = NetworkConnection(host: "example.com", port: 8080)

// the framework accepts generic data types
// send strings
connection.send(message: "Hello World!")

// send data
connection.send(message: Data(count: 100))
```

## Author:
👨🏼‍💻 [Vinzenz Weist](https://github.com/Vinz1911)
