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
    private var openAISpeakingService = OpenAISpeakingService()
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
        
        // Configure recording URL handler
        openAIVTTService.onRecordingStarted = { [weak self] in
            DispatchQueue.main.async {
                if let url = self?.openAIVTTService.recordingURL {
                    print("Recording URL set: \(url.path)")
                    self?.recordingURL = url
                }
            }
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        // Check if we're already processing a previous recording or waiting for AI response
        guard !isProcessing else {
            print("Cannot start recording while processing a previous recording or waiting for AI response")
            transcribedText = "Please wait for processing to complete"
            
            // Set a timeout to clear the error message after a short while
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.transcribedText == "Please wait for processing to complete" {
                    self?.transcribedText = ""
                }
            }
            return
        }
        
        // Only set isRecording to true after successful start
        let success = openAIVTTService.startRecording()
        
        if !success {
            // If recording failed to start, show error message
            print("Failed to start recording")
            transcribedText = "Error: Could not start recording"
            
            // Set a timeout to clear the error message after a short while
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.transcribedText == "Error: Could not start recording" {
                    self?.transcribedText = ""
                }
            }
        } else {
            isRecording = true
        }
    }
    
    func stopRecording() {
        // Only stop if we're actually recording
        if isRecording {
            openAIVTTService.stopRecording()
            
            // Note: isRecording will be set to false in the completion handlers
            // But set a timeout just in case
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if self?.isRecording == true {
                    self?.isRecording = false
                    self?.transcribedText = "Recording timed out"
                    
                    // Clear the timeout message after a short while
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        if self?.transcribedText == "Recording timed out" {
                            self?.transcribedText = ""
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Set processing flag to prevent new recordings during message processing
        isProcessing = true
        
        let userMessage = Message(
            id: UUID(),
            content: text,
            sender: .user,
            timestamp: Date(),
            corrections: []
        )
        
        messages.append(userMessage)
        transcribedText = ""
        
        // Get chat history to provide context to the AI
        let chatHistory = formatChatHistory()
        
        print("Starting AI processing")
        
        // Send the message to OpenAI and get a response
        openAISpeakingService.sendConversationalMessage(
            userMessage: text,
            previousMessages: chatHistory.dropLast(), // Drop the last message since we'll add it in the service
            completion: { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        // Create AI message with the response
                        let aiMessage = Message(
                            id: UUID(),
                            content: response,
                            sender: .ai,
                            timestamp: Date(),
                            corrections: []
                        )
                        
                        self.messages.append(aiMessage)
                        
                    case .failure(let error):
                        print("AI response error: \(error.localizedDescription)")
                        
                        // Create fallback message in case of error
                        let errorMessage = Message(
                            id: UUID(),
                            content: "Sorry, I couldn't process your message at this time.",
                            sender: .ai,
                            timestamp: Date(),
                            corrections: []
                        )
                        
                        self.messages.append(errorMessage)
                    }
                    
                    // Clear the processing flag only after everything is complete
                    print("AI processing complete, ready for new recording")
                    self.isProcessing = false
                }
            }
        )
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
        
        // Create translation request message
        let translationMessages: [ChatMessage] = [
            ChatMessage(role: "system", content: "You are a helpful AI translator. Translate the following text to Chinese. Only respond with the translation, nothing else."),
            ChatMessage(role: "user", content: "Please translate this to Chinese: \(message.content)")
        ]
        
        // Send the translation request
        openAISpeakingService.sendMessage(messages: translationMessages) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                var updatedMessage = message
                
                switch result {
                case .success(let translatedText):
                    updatedMessage.translation = translatedText
                    
                case .failure(let error):
                    print("Translation error: \(error.localizedDescription)")
                    updatedMessage.translation = "无法翻译文本。请稍后再试。" // Cannot translate text. Please try again later.
                }
                
                // Update the message in the array
                self.messages[index] = updatedMessage
                self.isProcessing = false
            }
        }
    }
    
    func playRecording() {
        // Check if we have a recording URL
        guard let recordingURL = recordingURL else {
            print("No recording URL available")
            return
        }
        
        do {
            // Create a new audio player with the recording URL
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = nil // We don't need a delegate for simple playback
            audioPlayer?.prepareToPlay()
            
            // Start playback
            if audioPlayer?.play() == true {
                print("Started playing recording")
            } else {
                print("Failed to start playing recording")
            }
        } catch {
            print("Error playing recording: \(error.localizedDescription)")
        }
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