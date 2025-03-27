//
//  ConversationView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showCorrectionDetail = false
    @State private var selectedCorrection: GrammarCorrection? = nil
    @State private var expandedCorrectionId: UUID? = nil
    @State private var elapsedTime: Int = 0 // Start from zero
    @State private var timer: Timer? = nil
    
    init(topic: Topic? = nil) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(topic: topic))
    }
    
    var body: some View {
        mainContentView
            .navigationBarTitle("Conversation", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: backButton)
            .sheet(isPresented: $showCorrectionDetail) {
                if let correction = selectedCorrection {
                    CorrectionDetailView(correction: correction)
                }
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
    }
    
    // Break up the complex body into smaller views
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Topic header
            topicHeader
            
            // Chat messages
            messagesContent
            
            // Input area
            inputArea
        }
    }
    
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
    
    private var messagesContent: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                messagesStack(scrollView: scrollView)
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(scrollView: scrollView)
            }
            .onChange(of: viewModel.isProcessing) { isProcessing in
                if isProcessing {
                    scrollToProcessingIndicator(scrollView: scrollView)
                }
            }
        }
    }
    
    private func messagesStack(scrollView: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 20) {
            // Message list
            ForEach(viewModel.messages) { message in
                messageWithCorrections(message: message)
            }
            
            // Processing indicator
            if viewModel.isProcessing {
                processingIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func messageWithCorrections(message: Message) -> some View {
        VStack(spacing: 0) {
            // Message view
            MessageView(
                message: message,
                onBookmark: { viewModel.bookmarkMessage(message.id) },
                onPlayAudio: { viewModel.playAudio(for: message.id) },
                onTranslate: { /* Translation functionality */ },
                onPlayRecording: { viewModel.playRecording() }
            )
            .id(message.id)
            
            // Corrections view if applicable
            if message.sender == .user && message.content.contains("I wake up at 7 o'clock") {
                SpeakCheckerView(
                    corrections: [GrammarCorrection(original: "I eating breakfast", corrected: "I eat breakfast", explanation: "Use the simple present tense 'eat' instead of just the present participle 'eating'.")],
                    isExpanded: expandedCorrectionId == message.id,
                    score: 78,
                    onToggle: {
                        toggleCorrection(messageId: message.id)
                    }
                )
            } else if !message.corrections.isEmpty && message.sender == .user {
                correctionView(for: message)
            }
        }
    }
    
    private func correctionView(for message: Message) -> some View {
        SpeakCheckerView(
            corrections: message.corrections,
            isExpanded: expandedCorrectionId == message.id,
            score: Int.random(in: 70...98),
            onToggle: {
                toggleCorrection(messageId: message.id)
            }
        )
    }
    
    private var processingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            Spacer()
        }
        .id("processingIndicator")
    }
    
    private func toggleCorrection(messageId: UUID) {
        if expandedCorrectionId == messageId {
            expandedCorrectionId = nil
        } else {
            expandedCorrectionId = messageId
        }
    }
    
    private func scrollToBottom(scrollView: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func scrollToProcessingIndicator(scrollView: ScrollViewProxy) {
        withAnimation {
            scrollView.scrollTo("processingIndicator", anchor: .bottom)
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            if viewModel.isRecording {
                // Recording view
                VStack(spacing: 12) {
                    Text(viewModel.transcribedText)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    inputButtonsRow
                }
            } else {
                // Normal input view with buttons only
                inputButtonsRow
                    .padding(.vertical, 20)
            }
        }
        .background(Color.white)
    }
    
    private var topicHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Daily Routines")
                    .font(.headline)
                Text("Beginner Level")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(timeString(from: elapsedTime))
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
    
    private var inputButtonsRow: some View {
        HStack(spacing: 20) {
            Button(action: {
                // Idea button functionality
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: 70, height: 70)
                        .shadow(color: viewModel.isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.3), 
                                radius: viewModel.isRecording ? 10 : 5, 
                                x: 0, 
                                y: 0)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(viewModel.isRecording ? 1.05 : 1.0)
            .animation(viewModel.isRecording ? Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: viewModel.isRecording)
            
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct MessageView: View {
    let message: Message
    let onBookmark: () -> Void
    let onPlayAudio: () -> Void
    let onTranslate: () -> Void
    let onPlayRecording: () -> Void
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 8) {
                ZStack(alignment: .bottom) {
                    // Message content
                    VStack(alignment: .leading, spacing: 0) {
                        Text(message.content)
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                            .padding(.bottom, 36) // Space for the buttons
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(message.sender == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(18)
                    .cornerRadius(message.sender == .user ? 4 : 18, corners: message.sender == .user ? .bottomRight : .bottomLeft)
                    
                    // Controls overlay at bottom of bubble
                    HStack(spacing: 10) {
                        if message.sender == .ai {
                            Button(action: onTranslate) {
                                Image(systemName: "text.bubble")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: onPlayAudio) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        } else {
                            Spacer()
                            
                            Button(action: onPlayAudio) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: onPlayRecording) {
                                Image(systemName: "play")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            
            if message.sender == .ai {
                Spacer()
            }
        }
    }
}

struct SpeakCheckerView: View {
    let corrections: [GrammarCorrection]
    let isExpanded: Bool
    let score: Int
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(score >= 90 ? Color.green : (score >= 75 ? Color.orange : Color.orange))
                                .frame(width: 34, height: 34)
                            
                            Text(String(score))
                                .font(.system(size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("Speak Checker")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Content - only show when expanded
            if isExpanded {
                // Grammar section
                categorySectionView(name: "Grammar")
                
                // Vocabulary section
                categorySectionView(name: "Vocabulary")
                
                // Pronunciation section  
                categorySectionView(name: "Pronunciation")
                
                // Fluency section
                categorySectionView(name: "Fluency")
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Helper function to create a category section
    private func categorySectionView(name: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name.uppercased())
                .font(.system(size: 12))
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.leading, 8)
                .overlay(
                    Rectangle()
                        .frame(width: 3)
                        .foregroundColor(.blue),
                    alignment: .leading
                )
                .padding(.bottom, 4)
            
            // Show first correction as an example
            if let correction = corrections.first {
                // Error text
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 18)
                    
                    Text(correction.original)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .strikethrough()
                }
                
                // Correction text
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .frame(width: 18)
                    
                    Text(correction.corrected)
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                        .underline()
                }
                
                // Explanation
                Text(correction.explanation)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.leading, 26)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}

struct CorrectionDetailView: View {
    let correction: GrammarCorrection
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(correction.original)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correction")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text(correction.corrected)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(correction.explanation)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationBarTitle("Grammar Correction", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationView {
        ConversationView()
    }
}