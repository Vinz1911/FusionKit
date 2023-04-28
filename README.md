# FusionKit

`FusionKit` is a library which implements the `Fusion Framing Protocol (FFP)`. The `Fusion Framing Protocol (FFP)` is proprietary networking protocol which uses a small and lightweight header with a performance as fast as raw tcp performance. Built directly on top of Apples `Network.framework` with support for plain tcp and tls encrypted connections. The implementation for the host is [Fusion](https://github.com/Vinz1911/fusion) written in golang with awesome concurrency support to ensure maximum performance.

# Overview
### License:
[![License](https://img.shields.io/badge/license-GPLv3-blue.svg?longCache=true&style=flat)](https://github.com/Vinz1911/FusionKit/blob/main/LICENSE)

### Swift Version:
[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?logo=swift&style=flat)](https://swift.org) [![Swift 5.5](https://img.shields.io/badge/SPM-Support-orange.svg?logo=swift&style=flat)](https://swift.org)

### Coverage:
[![codecov](https://codecov.io/github/Vinz1911/FusionKit/branch/main/graph/badge.svg?token=EE3S0BOINS)](https://codecov.io/github/Vinz1911/FusionKit)

## Installation:
### Swift Packages
[Swift Package Manager](https://developer.apple.com/documentation/swift_packages). Just add this repo to your project.

## Import:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FNConnection(host: "example.com", port: 8080)

// support for NWParameters, tls example:
let connection = FNConnection(host: "example.com", port: 8080, parameters: .tls)

// ...
```

## Callback:
```swift
// import the Framework
import FusionKit

// create a new connection
let connection = FNConnection(host: "example.com", port: 8080)

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
import FusionKit

// create a new connection
let connection = FNConnection(host: "example.com", port: 8080)

// the framework accepts generic data types
// send strings
connection.send(message: "Hello World!")

// send data
connection.send(message: Data(count: 100))
```

## Author:
👨🏼‍💻 [Vinzenz Weist](https://github.com/Vinz1911)
