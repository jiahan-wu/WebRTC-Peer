# WebRTC iOS Peer App

A native iOS application for real-time video conferencing using WebRTC technology.

## Overview

This iOS app demonstrates WebRTC (Web Real-Time Communication) capabilities by:
- Establishing peer-to-peer video calls
- Connecting to a signaling server for session negotiation
- Supporting multiple concurrent video streams
- Rendering video using Metal for optimal performance

## Requirements

- Running signaling server (see [WebRTC-Signaling-Server](https://github.com/jiahan-wu/WebRTC-Signaling-Server))

## Architecture

### Key Components

- **WebSocketClient**: Handles communication with the signaling server
- **ViewController**: Manages the UI and WebRTC connection logic
- **MTLVideoCollectionViewCell**: Renders video streams with Metal
- **Events**: Defines the signaling protocol messages

### WebRTC Implementation

The app uses WebRTC to:
- Capture local audio and video from device cameras
- Establish peer connections using ICE framework
- Exchange SDP (Session Description Protocol) messages
- Stream media data directly between peers
- Display remote video streams in a grid layout

## Usage

1. Launch the app and ensure the signaling server is running
2. Enter a unique user ID in the text field
3. Tap Connect to join the session
4. As other users join, their video streams will appear automatically
5. Tap Disconnect to leave the session

## License

[MIT License](LICENSE)