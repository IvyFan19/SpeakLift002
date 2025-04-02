//
//  ChatModels.swift
//  SpeakLiftApp-002
//
//  Created on 3/26/25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct AIResponse {
    let content: String
    let corrections: [GrammarCorrection]
}

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
} 