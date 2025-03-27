//
//  ConversationViewModel.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation
import Combine
import AVFoundation

class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isProcessing = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var apiService: OpenAIService?
    
    init(topic: Topic? = nil) {
        // For preview and testing purposes, load example messages
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            loadExampleMessages()
        } else if let topic = topic {
            // Add initial AI message based on topic
            let initialMessage = Message(
                id: UUID(),
                content: "Let's talk about \(topic.title). \(topic.description)",
                sender: .ai,
                timestamp: Date(),
                corrections: []
            )
            messages.append(initialMessage)
        }
        #endif
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            transcribedText = "Listening..."
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        transcribedText = "Processing..."
        
        // In a real implementation, this would send the audio to OpenAI for transcription
        // For now, we'll simulate the process with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Simulate transcription result
            self.transcribedText = "I'm planning to travel to Japan next month. Can you help me with some useful phrases?"
            self.sendMessage(self.transcribedText)
        }
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(
            id: UUID(),
            content: text,
            sender: .user,
            timestamp: Date(),
            corrections: []
        )
        
        messages.append(userMessage)
        transcribedText = ""
        isProcessing = true
        
        // In a real implementation, this would send the message to OpenAI API
        // For now, we'll simulate the response with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate AI response with grammar corrections
            let corrections: [GrammarCorrection] = [
                GrammarCorrection(original: "I'm planning", corrected: "I'm planning", explanation: "Correct usage of present continuous tense."),
                GrammarCorrection(original: "next month", corrected: "next month", explanation: "Correct time expression.")
            ]
            
            let aiMessage = Message(
                id: UUID(),
                content: "That's great! Japan is a beautiful country with a rich culture. Here are some useful phrases for your trip:\n\n- こんにちは (Konnichiwa) - Hello\n- ありがとう (Arigatou) - Thank you\n- すみません (Sumimasen) - Excuse me/I'm sorry\n- お願いします (Onegaishimasu) - Please\n\nWould you like to practice these phrases or learn more specific ones for situations like ordering food or asking for directions?",
                sender: .ai,
                timestamp: Date(),
                corrections: corrections
            )
            
            self.messages.append(aiMessage)
            self.isProcessing = false
        }
    }
    
    func bookmarkMessage(_ messageId: UUID) {
        // In a real implementation, this would save the message to bookmarks
        print("Bookmarked message: \(messageId)")
    }
    
    func playAudio(for messageId: UUID) {
        // In a real implementation, this would use text-to-speech to play the message
        print("Playing audio for message: \(messageId)")
    }
    
    // MARK: - Helper Methods
    
    private func loadExampleMessages() {
        let exampleMessages: [Message] = [
            Message(
                id: UUID(),
                content: "Now let's talk about your daily routine. To sound native-like, try: \"I usually wake up at 7 o'clock and have breakfast right after.\"",
                sender: .ai,
                timestamp: Date().addingTimeInterval(-300),
                corrections: []
            ),
            Message(
                id: UUID(),
                content: "I wake up at 7 o'clock every morning and then I eat breakfast.",
                sender: .user,
                timestamp: Date().addingTimeInterval(-240),
                corrections: []
            ),
            Message(
                id: UUID(),
                content: "That's a good time to start the day! I noticed a small grammar mistake in your sentence. You said \"I eating breakfast\" instead of \"I eat breakfast\" or \"I am eating breakfast.\" Would you like to try again?",
                sender: .ai,
                timestamp: Date().addingTimeInterval(-180),
                corrections: [
                    GrammarCorrection(original: "I eating breakfast", corrected: "I eat breakfast", explanation: "Use the simple present tense 'eat' instead of just the present participle 'eating'.")
                ]
            ),
            Message(
                id: UUID(),
                content: "Perfect! What do you usually have for breakfast?",
                sender: .ai,
                timestamp: Date().addingTimeInterval(-120),
                corrections: []
            )
        ]
        
        messages = exampleMessages
    }
}

// MARK: - Message Model

struct Message: Identifiable {
    let id: UUID
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let corrections: [GrammarCorrection]
}

enum MessageSender {
    case user
    case ai
}

struct GrammarCorrection: Identifiable {
    let id = UUID()
    let original: String
    let corrected: String
    let explanation: String
}