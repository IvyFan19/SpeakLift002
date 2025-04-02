//
//  HomeView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var topicsViewModel = TopicsViewModel()
    @State private var navigateToConversation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hi, \(User.example.name)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Ready to improve your English today?")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Practice Button
                    Button(action: {
                        navigateToConversation = true
                    }) {
                        HStack {
                            Image(systemName: "mic")
                                .font(.system(size: 18))
                            Text("Start Speaking Practice")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 28)
                        .background(Color.blue)
                        .cornerRadius(24)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Level")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(User.example.proficiencyLevel.rawValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Practice Streak")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("5 days")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("75% to next level")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: geometry.size.width, height: 8)
                                        .opacity(0.1)
                                        .foregroundColor(.gray)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .frame(width: geometry.size.width * 0.75, height: 8)
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Recommended Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended Topics")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(topicsViewModel.recommendedTopics) { topic in
                                    NavigationLink(destination: ConversationView(topic: topic)) {
                                        TopicCardView(topic: topic)
                                            .frame(width: 280, height: 150)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Conversations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Conversations")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<2) { _ in
                                NavigationLink(destination: ConversationView(topic: topicsViewModel.recommendedTopics[0])) {
                                    RecentConversationRow()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: 
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .foregroundColor(.primary)
                }
            )
            .navigationDestination(isPresented: $navigateToConversation) {
                ConversationView()
            }
        }
    }
}

struct TopicCardView: View {
    let topic: Topic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(colorFromString(topic.iconBackgroundColor))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: topic.iconName)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(topic.level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelBackgroundColor(for: topic.level))
                    .foregroundColor(levelTextColor(for: topic.level))
                    .cornerRadius(10)
            }
            
            Text(topic.title)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)
            
            Text(topic.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func levelBackgroundColor(for level: ProficiencyLevel) -> Color {
        switch level {
        case .beginner:
            return Color.blue.opacity(0.1)
        case .intermediate:
            return Color.green.opacity(0.1)
        case .advanced:
            return Color.orange.opacity(0.1)
        }
    }
    
    private func levelTextColor(for level: ProficiencyLevel) -> Color {
        switch level {
        case .beginner:
            return Color.blue
        case .intermediate:
            return Color.green
        case .advanced:
            return Color.orange
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue":
            return Color.blue
        case "green":
            return Color.green
        case "orange":
            return Color.orange
        case "red":
            return Color.red
        case "purple":
            return Color.purple
        default:
            return Color.blue
        }
    }
}

struct RecentConversationRow: View {
    var body: some View {
        HStack(spacing: 16) {
            // Conversation icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            // Conversation details
            VStack(alignment: .leading, spacing: 4) {
                Text("Travel Plans")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("You: I'm planning to visit Japan next month...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text("2 hours ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Score indicator
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text("4.5")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}