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
    private var openAIService = OpenAIService()
    private var recordingURL: URL?
    
    init(topic: Topic? = nil) {
        // Setup OpenAI Service handlers
        configureOpenAIService()
        
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
    
    private func configureOpenAIService() {
        // Configure transcription update handler
        openAIService.onTranscriptionUpdate = { [weak self] text in
            DispatchQueue.main.async {
                self?.transcribedText = text
            }
        }
        
        // Configure transcription complete handler
        openAIService.onTranscriptionComplete = { [weak self] finalText in
            DispatchQueue.main.async {
                self?.transcribedText = finalText
                
                // Send the transcribed text as a message if it's not empty
                if !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self?.sendMessage(finalText)
                } else {
                    self?.transcribedText = ""
                }
            }
        }
        
        // Configure error handler
        openAIService.onTranscriptionError = { [weak self] error in
            DispatchQueue.main.async {
                print("Transcription error: \(error.localizedDescription)")
                self?.transcribedText = "Error: Could not transcribe audio"
                self?.isRecording = false
            }
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        // Start realtime transcription using OpenAI API
        transcribedText = "Listening..."
        isRecording = true
        
        // First start local recording
        startLocalRecording { success in
            if success {
                // Then start the OpenAI transcription
                self.openAIService.startRealtimeTranscription()
            } else {
                // If local recording fails, reset state
                self.isRecording = false
                self.transcribedText = "Error: Could not start recording"
            }
        }
    }
    
    func stopRecording() {
        // Stop realtime transcription
        openAIService.stopRealtimeTranscription()
        
        // Also stop the local recording
        stopLocalRecording()
        
        isRecording = false
    }
    
    private func startLocalRecording(completion: @escaping (Bool) -> Void) {
        // We won't configure the audio session here since OpenAIService will do it
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            guard let recordingURL = recordingURL else {
                completion(false)
                return
            }
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Let the recorder start with existing audio session
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.record()
            completion(true)
        } catch {
            print("Failed to start local recording: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    private func stopLocalRecording() {
        audioRecorder?.stop()
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
        
        // Convert message history to format expected by OpenAI
        let chatMessages = formatChatHistory()
        
        // Send to OpenAI service
        openAIService.sendMessage(messages: chatMessages)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error sending message: \(error.localizedDescription)")
                    self?.isProcessing = false
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                let aiMessage = Message(
                    id: UUID(),
                    content: response.content,
                    sender: .ai,
                    timestamp: Date(),
                    corrections: response.corrections
                )
                
                self.messages.append(aiMessage)
                self.isProcessing = false
            })
            .store(in: &cancellables)
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
        
        // Call OpenAI service to translate the message
        openAIService.translateToChineseMessage(message.content)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error translating message: \(error.localizedDescription)")
                }
                self?.isProcessing = false
            }, receiveValue: { [weak self] translatedText in
                guard let self = self else { return }
                
                // Create a new message with the translation
                var updatedMessage = message
                updatedMessage.translation = translatedText
                
                // Update the message in the array
                self.messages[index] = updatedMessage
            })
            .store(in: &cancellables)
    }
    
    func playRecording() {
        guard let recordingURL = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
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