# Fusion Framing Protocol (FFP)

## Abstract

This document specifies a new binary framing protocol, called Fusion Framing Protocol. The protocol provides a generic and efficient way to send text, binary, and control messages over a network connection. It is designed to be simple, flexible, and extensible, while maintaining the integrity and security of data. This protocol is suitable for use in various network applications, such as client-server and peer-to-peer communication.

## Table of Contents

1. Introduction
2. Protocol Overview
3. Framing
   3.1 Frame Format
   3.2 Frame Types
   3.3 Control Frames
4. Message Handling
5. Security Considerations
6. IANA Considerations

## 1. Introduction

As network applications become more complex and diverse, there is a growing need for a simple and efficient way to send different types of messages over a network connection. The Fusion Framing Protocol (FFP) is designed to meet this need by providing a generic and extensible binary framing protocol. The protocol supports the transmission of text, binary, and control messages, and ensures the integrity and security of data by including a message hash in each frame.

This document defines the framing format, frame types, and message handling procedures for the FFP. It also discusses security considerations and IANA considerations related to the protocol.

## 2. Protocol Overview

The FFP is a binary framing protocol that uses a simple header and payload structure. The header contains an opcode that indicates the type of the frame, the length of the frame, and a hash value computed over the control data of the frame. The payload contains the actual message data.

The protocol supports three types of frames:

Text frames, for transmitting UTF-8 encoded text messages
Binary frames, for transmitting arbitrary binary data
Control frames, for transmitting control messages, such as pings
To ensure the integrity of the data, each frame includes a hash value computed using the SHA-256 algorithm. The receiver can verify the hash value to ensure that the frame has not been tampered with or corrupted during transmission.

## 3. Framing

### 3.1 Frame Format
Each frame in the FFP consists of a header and a payload.
Frames in the Framing Protocol have the following structure:

```shell
 0                   1
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
+-+-------+---------------------+
|O|Length |    Hash SHA256      |
|P| (4)   |        (32)         |
|C|       |                     |
+---------+ - - - - - - - - - - +
|      hash value continued     |
+ - - - - +---------------------+
|         |    Payload Data     |
+ - - - - + - - - - - - - - - - +
:    Payload Data continued ... :
+ - - - - - - - - - - - - - - - +
|    Payload Data continued ... |
+-------------------------------+
```
The header contains the following fields:

- Opcode (1 byte): Indicates the type of the frame (text, binary, or control)
- Length (4 bytes): Specifies the total length of the frame, including the header and payload, in network byte order (big-endian)
- Hash (32 bytes): A SHA-256 hash computed over the control data of the frame (i.e., the opcode and length fields)
- The payload contains the actual message data, which can be text, binary, or control data, depending on the frame type.

### 3.2 Frame Types
The FFP supports three types of frames, as indicated by the opcode field in the header:

- Text frames (opcode 0x1): These frames carry UTF-8 encoded text messages. The payload contains the text data.
- Binary frames (opcode 0x2): These frames carry arbitrary binary data. The payload contains the binary data.
- Control frames (opcode 0x3): These frames carry control messages, such as pings. The payload contains the control data, which is a 16-bit unsigned integer.

### 3.3 Control Frames
Control frames are used to transmit control messages between endpoints. Currently, the only control message supported by the FFP is the ping message, which can be used to check the liveliness of a connection or measure latency.

A ping message is a control frame with a payload consisting of a 16-bit unsigned integer, which represents the size of the data being sent in the ping. The receiver of a ping message should respond with a pong message, which is also a control frame with the same payload as the ping message. This allows the sender to calculate the round-trip time for the ping message.

## 4. Message Handling

When receiving a frame, an endpoint should perform the following steps:

1. Verify the frame's hash value by computing the SHA-256 hash over the control data of the frame (opcode and length fields) and comparing it to the hash value in the frame header. If the hash values do not match, the frame is considered invalid and should be discarded.
2. Depending on the frame type, process the payload as follows:
  - For text frames, decode the UTF-8 encoded payload as a text message and pass it to the application layer.
  - For binary frames, pass the binary payload to the application layer.
  - For control frames, process the control message according to its type (e.g., respond to a ping message with a pong message).
 
When sending a message, an endpoint should perform the following steps:

1. Create a frame with the appropriate opcode for the message type (text, binary, or control).
2. Compute the length of the frame, including the header and payload, and set the length field in the header.
3. Compute the SHA-256 hash over the control data of the frame (opcode and length fields) and set the hash field in the header.
4. Append the message payload to the frame.
5. Transmit the frame over the network connection.

## 5. Security Considerations

The FFP includes a hash value in each frame to ensure the integrity of the data. However, this hash value does not provide any confidentiality or authentication. To secure the communication between endpoints, the FFP should be used in conjunction with a secure transport layer, such as Transport Layer Security (TLS).

Additionally, the protocol does not provide any built-in mechanism for handling malicious or malformed frames. It is the responsibility of the application layer to handle such cases appropriately, for example, by closing the connection or implementing rate-limiting mechanisms.

## 6. IANA Considerations

There are no IANA considerations for the FFP at this time. Future extensions or revisions of the protocol may require IANA registration of new frame types, control messages, or other protocol elements.
