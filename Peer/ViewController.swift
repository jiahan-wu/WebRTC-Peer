//
//  ViewController.swift
//  Peer
//
//  Created by Jia-Han Wu on 2025/4/13.
//

import UIKit
import WebRTC

class ViewController: UIViewController {
    
    // MARK: UI Elements
    
    @IBOutlet weak var userIdTextField: UITextField!
    
    @IBOutlet weak var connectButton: UIButton!
    
    // MARK: Properties
    
    private var webSocketClient: WebSocketClient?
    
    private let jsonDecoder = JSONDecoder()
    
    private let jsonEncoder = JSONEncoder()
    
    // MARK: WebRTC Properties
    
    private var peerConnectionsByUserId = [String: RTCPeerConnection]()
    
    private let factory: RTCPeerConnectionFactory = {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }()
    
    private let mediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: nil
    )
    
    private var audioTrack: RTCAudioTrack?
    
    private var videoTrack: RTCVideoTrack?
    
    private var cameraVideoCapturer: RTCCameraVideoCapturer?
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAudioSession()
        configureAudioTrack()
        configureVideoTrack()
    }
    
    // MARK: Setup Methods
    
    private func configureAudioSession() {
        let audioSession = RTCAudioSession.sharedInstance()
        audioSession.add(self)
        
        do {
            let configuration = RTCAudioSessionConfiguration.webRTC()
            configuration.categoryOptions = [.defaultToSpeaker]
            
            audioSession.lockForConfiguration()
            try audioSession.setConfiguration(configuration, active: true)
            audioSession.unlockForConfiguration()
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func configureAudioTrack() {
        let audioSource = factory.audioSource(with: mediaConstraints)
        
        audioTrack = factory.audioTrack(
            with: audioSource,
            trackId: ""
        )
    }
    
    private func configureVideoTrack() {
        let videoSource = factory.videoSource()
        
        cameraVideoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: ""
        )
    }
    
    // MARK: UI Actions
    
    @IBAction func handleUserIdentifierTextFieldChanged(_ sender: UITextField) {
        connectButton.isEnabled = !(sender.text?.isEmpty ?? true)
    }
    
    @IBAction func handleConnectButtonPressed(_ sender: UIButton) {
        if sender.titleLabel?.text == "Connect" {
            sender.setTitle("Disconnect", for: .normal)
            userIdTextField.isEnabled = false
            connect()
        } else {
            sender.setTitle("Connect", for: .normal)
            userIdTextField.isEnabled = true
            disconnect()
        }
    }
    
    // MARK: WebSocket Methods
    
    private func connect() {
        let url = URL(string: "wss://52bb-2407-4d00-4c00-1976-29d5-5c83-699b-a5e9.ngrok-free.app/signals")!
        webSocketClient = WebSocketClient(url: url)
        webSocketClient?.delegate = self
        webSocketClient?.connect()
        Task {
            do {
                let userJoinedEvent = Event.UserJoinedEvent(
                    userId: userIdTextField.text ?? "")
                let userJoinedEventJSONData = try jsonEncoder.encode(userJoinedEvent)
                try await webSocketClient?.send(userJoinedEventJSONData)
            } catch {
                print("Failed to send user joined event: \(error)")
            }
        }
    }
    
    private func disconnect() {
        webSocketClient?.disconnect()
        webSocketClient = nil
    }
    
    // MARK: Event Handlers
    
    private func handle(_ userJoinedEvent: Event.UserJoinedEvent) async {
        guard userJoinedEvent.userId != userIdTextField.text else {
            return
        }
        
        if let oldPeerConnection = peerConnectionsByUserId[userJoinedEvent.userId] {
            oldPeerConnection.close()
        }
        
        guard let peerConnection = createPeerConnection() else {
            print("Failed to create peer connection.")
            return
        }
        
        if let audioTrack {
            peerConnection.add(audioTrack, streamIds: ["localStream"])
        }
        
        if let videoTrack {
            peerConnection.add(videoTrack, streamIds: ["localStream"])
        }
        
        do {
            let offer = try await peerConnection.offer(for: mediaConstraints)
            
            do {
                try await peerConnection.setLocalDescription(offer)
                
                Task {
                    do {
                        let offerEvent = Event.OfferEvent(
                            sdp: offer.sdp,
                            from: userIdTextField.text ?? "",
                            to: userJoinedEvent.userId
                        )
                        let offerEventJSONData = try jsonEncoder.encode(offerEvent)
                        try await webSocketClient?.send(offerEventJSONData)
                        peerConnectionsByUserId[userJoinedEvent.userId] = peerConnection
                    } catch {
                        print("Failed to send offer event: \(error)")
                    }
                }
            } catch {
                print("Failed to set local description: \(error)")
            }
        } catch {
            print("Failed to create offer: \(error)")
        }
    }
    
    func handle(_ offerEvent: Event.OfferEvent) async {
        guard offerEvent.to == userIdTextField.text else {
            return
        }
        
        if let oldPeerConnection = peerConnectionsByUserId[offerEvent.from] {
            oldPeerConnection.close()
        }
        
        guard let peerConnection = createPeerConnection() else {
            print("Failed to create peer connection.")
            return
        }
        
        if let audioTrack {
            peerConnection.add(audioTrack, streamIds: ["localStream"])
        }
        
        if let videoTrack {
            peerConnection.add(videoTrack, streamIds: ["localStream"])
        }
        
        let remoteDescription =  RTCSessionDescription(
            type: .offer,
            sdp: offerEvent.sdp
        )
        do {
            try await peerConnection.setRemoteDescription(remoteDescription)
            
            do {
                let answer = try await peerConnection.answer(for: mediaConstraints)
                
                do {
                    try await peerConnection.setLocalDescription(answer)
                    
                    Task {
                        do {
                            let answerEvent = Event.AnswerEvent(
                                sdp: answer.sdp,
                                from: offerEvent.to,
                                to: offerEvent.from
                            )
                            let answerEventJSONdata = try jsonEncoder.encode(answerEvent)
                            try await webSocketClient?.send(answerEventJSONdata)
                            peerConnectionsByUserId[offerEvent.from] = peerConnection
                        } catch {
                            print("Failed to send user joined event: \(error)")
                        }
                    }
                } catch {
                    print("Faield to set local description: \(error)")
                }
            } catch {
                print("Failed to create answer: \(error)")
            }
        } catch {
            print("Failed to set remote description: \(error)")
        }
    }
    
    func handle(_ answerEvent: Event.AnswerEvent) async {
        guard let peerConnection = peerConnectionsByUserId[answerEvent.from] else {
            return
        }
        
        let remoteDescription = RTCSessionDescription(
            type: .answer,
            sdp: answerEvent.sdp
        )
        
        do {
            try await peerConnection.setRemoteDescription(remoteDescription)
        } catch {
            print("Failed to set remote description: \(error)")
        }
    }
    
    func handle(_ iceCandidateGeneratedEvent: Event.ICECandidateGeneratedEvent) async {
        guard iceCandidateGeneratedEvent.to == userIdTextField.text else {
            return
        }
        
        guard let peerConnection = peerConnectionsByUserId[iceCandidateGeneratedEvent.from] else {
            return
        }
        
        let iceCandidate = RTCIceCandidate(
            sdp: iceCandidateGeneratedEvent.iceCandidate.sdp,
            sdpMLineIndex: iceCandidateGeneratedEvent.iceCandidate.sdpMLineIndex,
            sdpMid: iceCandidateGeneratedEvent.iceCandidate.sdpMid
        )
        
        do {
            try await peerConnection.add(iceCandidate)
        } catch {
            print("Failed to add ICE candidate: \(error)")
        }
    }
    
    func handle(_ iceCandidatesRemovedEvent: Event.ICECandidatesRemovedEvent) {
        guard iceCandidatesRemovedEvent.to == userIdTextField.text else {
            return
        }
        
        guard let peerConnection = peerConnectionsByUserId[iceCandidatesRemovedEvent.from] else {
            return
        }
        
        let iceCandidates = iceCandidatesRemovedEvent.iceCandidates.map {
            RTCIceCandidate(
                sdp: $0.sdp,
                sdpMLineIndex: $0.sdpMLineIndex,
                sdpMid: $0.sdpMid
            )
        }
        
        peerConnection.remove(iceCandidates)
    }
    
    // MARK: WebRTC Helper Methods
    
    private func createPeerConnection() -> RTCPeerConnection? {
        let configuration = RTCConfiguration()
        let iceServers = [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302",
            "stun:stun2.l.google.com:19302",
            "stun:stun3.l.google.com:19302",
            "stun:stun4.l.google.com:19302",
        ]
        configuration.iceServers = [RTCIceServer(urlStrings: iceServers)]
        configuration.sdpSemantics = .unifiedPlan
        configuration.continualGatheringPolicy = .gatherContinually
        
        return factory.peerConnection(
            with: configuration,
            constraints: mediaConstraints,
            delegate: self
        )
    }
    
}

// MARK: RTCAudioSessionDelegate

extension ViewController: RTCAudioSessionDelegate {}

// MARK: WebSocketClientDelegate

extension ViewController: WebSocketClientDelegate {
    
    func webSocketClientDidDisconnect(_ client: WebSocketClient) {
        Task { @MainActor in
            userIdTextField.isEnabled = true
            connectButton.setTitle("Connect", for: .normal)
        }
    }
    
    func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
        do {
            let event = try jsonDecoder.decode(Event.self, from: data)
            
            switch event.type {
            case Event.UserJoinedEvent.type:
                let userJoinedEvent = try jsonDecoder.decode(Event.UserJoinedEvent.self, from: data)
                Task { @MainActor in
                    await handle(userJoinedEvent)
                }
            case Event.OfferEvent.type:
                let offerEvent = try jsonDecoder.decode(Event.OfferEvent.self, from: data)
                Task { @MainActor in
                    await handle(offerEvent)
                }
            case Event.AnswerEvent.type:
                let answerEvent = try jsonDecoder.decode(Event.AnswerEvent.self, from: data)
                Task { @MainActor in
                    await handle(answerEvent)
                }
            case Event.ICECandidateGeneratedEvent.type:
                let iceCandidateGeneratedEvent = try jsonDecoder.decode(Event.ICECandidateGeneratedEvent.self, from: data)
                Task { @MainActor in
                    await handle(iceCandidateGeneratedEvent)
                }
            case Event.ICECandidatesRemovedEvent.type:
                let iceCandidatesRemovedEvent = try jsonDecoder.decode(Event.ICECandidatesRemovedEvent.self, from: data)
                Task { @MainActor in
                    handle(iceCandidatesRemovedEvent)
                }
            default:
                break
            }
        } catch {
            print("Failed to decode event: \(error)")
        }
    }
    
}

// MARK: RTCPeerConnectionDelegate

extension ViewController: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection didChange stateChanged: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("peerConnection didAdd stream: \(stream)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection didRemove stream: \(stream)")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnection shouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection didChange newState: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection didChange newState: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("peerConnection didGenerate candidate: \(candidate)")
        
        Task { @MainActor in
            let from = userIdTextField.text ?? ""
            let userIds = peerConnectionsByUserId.keys
            let iceCandidate = Event.ICECandidate(
                sdp: candidate.sdp,
                sdpMLineIndex: candidate.sdpMLineIndex,
                sdpMid: candidate.sdpMid
            )
            for to in userIds {
                let iceCandidateGeneratedEvent = Event.ICECandidateGeneratedEvent(
                    iceCandidate: iceCandidate,
                    from: from,
                    to: to
                )
                do {
                    let iceCandidateGeneratedEventJSONData = try jsonEncoder.encode(iceCandidateGeneratedEvent)
                    do {
                        try await webSocketClient?.send(iceCandidateGeneratedEventJSONData)
                    } catch {
                        print("Failed to send iceCandidateGeneratedEventJSONData: \(error)")
                    }
                } catch {
                    print("Failed to encode iceCandidateGeneratedEventJSONData: \(error)")
                }
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection didRemove candidates: \(candidates)")
        
        Task { @MainActor in
            let from = userIdTextField.text ?? ""
            let userIds = peerConnectionsByUserId.keys
            let iceCandidates = candidates.map {
                Event.ICECandidate(
                    sdp: $0.sdp,
                    sdpMLineIndex: $0.sdpMLineIndex,
                    sdpMid: $0.sdpMid
                )
            }
            for to in userIds {
                let iceCandidatesRemovedEvent = Event.ICECandidatesRemovedEvent(
                    iceCandidates: iceCandidates,
                    from: from,
                    to: to
                )
                do {
                    let iceCandidatesRemovedEventJSONData = try jsonEncoder.encode(iceCandidatesRemovedEvent)
                    do {
                        try await webSocketClient?.send(iceCandidatesRemovedEventJSONData)
                    } catch {
                        print("Failed to send iceCandidatesRemovedEventJSONData: \(error)")
                    }
                } catch {
                    print("Failed to encode iceCandidatesRemovedEventJSONData: \(error)")
                }
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection didOpen dataChannel: \(dataChannel)")
    }
    
}
