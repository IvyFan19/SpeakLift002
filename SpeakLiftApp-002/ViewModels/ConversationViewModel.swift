//
//  ConversationViewModel.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation
import Combine
import AVFoundation
// Import without module prefix since it's in the same target
// import Models.ChatModels

class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isProcessing = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var openAIVTTService = OpenAIVTTService()
    private var recordingURL: URL?
    
    init(topic: Topic? = nil) {
        // Setup OpenAI VTT Service handlers
        configureOpenAIVTTService()
        
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
    
    private func configureOpenAIVTTService() {
        // Configure speech-to-text completion handler
        openAIVTTService.onTranscriptionComplete = { [weak self] text in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("Transcription completed: \(text)")
                self.transcribedText = text
                
                // Send the transcribed text as a message if it's not empty
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.sendMessage(text)
                } else {
                    self.transcribedText = ""
                }
                
                self.isRecording = false
            }
        }
        
        // Configure recording started handler
        openAIVTTService.onRecordingStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.transcribedText = "Listening..."
            }
        }
        
        // Configure recording stopped handler
        openAIVTTService.onRecordingStopped = { [weak self] in
            DispatchQueue.main.async {
                self?.transcribedText = "Processing..."
            }
        }
        
        // Configure recording progress handler
        openAIVTTService.onRecordingProgress = { [weak self] level in
            // This could be used to show a visual indicator of recording level
        }
        
        // Configure error handler
        openAIVTTService.onTranscriptionError = { [weak self] error in
            DispatchQueue.main.async {
                print("Transcription error: \(error.localizedDescription)")
                self?.transcribedText = "Error: Could not transcribe audio"
                self?.isRecording = false
            }
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        isRecording = true
        
        // Start recording using the OpenAIVTTService
        if !openAIVTTService.startRecording() {
            // If recording failed to start, reset state
            print("Failed to start recording")
            isRecording = false
            transcribedText = "Error: Could not start recording"
        }
    }
    
    func stopRecording() {
        // Stop recording
        openAIVTTService.stopRecording()
        
        // Note: isRecording will be set to false in the completion handlers
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
        
        // For now, just simulate a response with no real AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Create a mock response 
            let aiMessage = Message(
                id: UUID(),
                content: "This is a placeholder response since the OpenAI service has been removed. Your message was: \"\(text)\"",
                sender: .ai,
                timestamp: Date(),
                corrections: []
            )
            
            self.messages.append(aiMessage)
            self.isProcessing = false
        }
    }
    
    private func formatChatHistory() -> [ChatMessage] {
        var chatMessages: [ChatMessage] = []
        
        // System message to set up the context for the AI
        chatMessages.append(ChatMessage(role: "system", content: "You are a helpful AI language tutor named SpeakLift. Your purpose is to help users practice English conversation while providing gentle grammar corrections."))
        
        // Add the conversation history (limit to last 10 messages to save on tokens)
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            let role = message.sender == .user ? "user" : "assistant"
            chatMessages.append(ChatMessage(role: role, content: message.content))
        }
        
        return chatMessages
    }
    
    func bookmarkMessage(_ messageId: UUID) {
        // Implement bookmarking functionality
        print("Bookmarking message: \(messageId)")
    }
    
    func playAudio(for messageId: UUID) {
        // Implement text-to-speech functionality
        print("Playing audio for message: \(messageId)")
    }
    
    func translateMessage(_ messageId: UUID) {
        // Find the message with the given ID
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              messages[index].sender == .ai else { return }
        
        // Only translate AI messages
        let message = messages[index]
        
        // If already translated, no need to translate again
        if message.translation != nil { return }
        
        // Show processing indicator
        isProcessing = true
        
        // Simulate translation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Create a mock translation (Chinese characters that say this is a placeholder)
            var updatedMessage = message
            updatedMessage.translation = "这是一个占位符翻译，因为OpenAI服务已被删除。"
            
            // Update the message in the array
            self.messages[index] = updatedMessage
            self.isProcessing = false
        }
    }
    
    func playRecording() {
        // This method remains for compatibility with the UI,
        // but would need implementation if you want to play back recordings
        print("Play recording requested (not implemented)")
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
    var translation: String? = nil
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