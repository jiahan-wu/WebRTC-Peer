//
//  Events.swift
//  Peer
//
//  Created by Jia-Han Wu on 2025/4/14.
//

import Foundation

struct Event: Codable {
    let type: String
}

// MARK: UserJoinedEvent

extension Event {
    
    struct UserJoinedEvent: Codable {
        
        enum CodingKeys: CodingKey {
            case type
            case userId
        }
        
        static let type = "user-joined"
        
        let userId: String
        
        init (userId: String) {
            self.userId = userId
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            userId = try values.decode(String.self, forKey: .userId)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(userId, forKey: .userId)
        }
        
    }
    
}

// MARK: OfferEvent

extension Event {
    
    struct OfferEvent: Codable {
        
        enum CodingKeys: CodingKey {
            case type
            case sdp
            case from
            case to
        }
        
        static let type = "offer"
        
        let sdp: String
        let from: String
        let to: String
        
        init (sdp: String, from: String, to: String) {
            self.sdp = sdp
            self.from = from
            self.to = to
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            sdp = try values.decode(String.self, forKey: .sdp)
            from = try values.decode(String.self, forKey: .from)
            to = try values.decode(String.self, forKey: .to)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(sdp, forKey: .sdp)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
        }
        
    }
    
}

// MARK: AnswerEvent

extension Event {
    
    struct AnswerEvent: Codable {
        
        enum CodingKeys: CodingKey {
            case type
            case sdp
            case from
            case to
        }
        
        static let type = "answer"
        
        let sdp: String
        let from: String
        let to: String
        
        init (sdp: String, from: String, to: String) {
            self.sdp = sdp
            self.from = from
            self.to = to
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            sdp = try values.decode(String.self, forKey: .sdp)
            from = try values.decode(String.self, forKey: .from)
            to = try values.decode(String.self, forKey: .to)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(sdp, forKey: .sdp)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
        }
        
    }
    
}

// MARK: ICECandidate

extension Event {
    
    struct ICECandidate: Codable {
        let sdp: String
        let sdpMLineIndex: Int32
        let sdpMid: String?
    }
    
}

// MARK: ICECandidateGeneratedEvent

extension Event {
    
    struct ICECandidateGeneratedEvent: Codable {
        
        enum CodingKeys: CodingKey {
            case type
            case iceCandidate
            case from
            case to
        }
        
        static let type = "ice-candidate-generated"
        
        let iceCandidate: ICECandidate
        let from: String
        let to: String
        
        init(
            iceCandidate: ICECandidate,
            from: String,
            to: String
        ) {
            self.iceCandidate = iceCandidate
            self.from = from
            self.to = to
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            iceCandidate = try values.decode(ICECandidate.self, forKey: .iceCandidate)
            from = try values.decode(String.self, forKey: .from)
            to = try values.decode(String.self, forKey: .to)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(iceCandidate, forKey: .iceCandidate)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
        }
        
    }
    
}

// MARK: ICECandidatesRemovedEvent

extension Event {
    
    struct ICECandidatesRemovedEvent: Codable {
        
        enum CodingKeys: CodingKey {
            case type
            case iceCandidates
            case from
            case to
        }
        
        static let type = "ice-candidates-removed"
        
        let iceCandidates: [ICECandidate]
        let from: String
        let to: String
        
        init(
            iceCandidates: [ICECandidate],
            from: String,
            to: String
        ) {
            self.iceCandidates = iceCandidates
            self.from = from
            self.to = to
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            iceCandidates = try values.decode([ICECandidate].self, forKey: .iceCandidates)
            from = try values.decode(String.self, forKey: .from)
            to = try values.decode(String.self, forKey: .to)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(iceCandidates, forKey: .iceCandidates)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
        }
        
    }
    
}
