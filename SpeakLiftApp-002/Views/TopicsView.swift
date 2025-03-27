//
//  TopicsView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

import SwiftUI

// Import shared components

struct TopicsView: View {
    @StateObject private var viewModel = TopicsViewModel()
    @State private var selectedCategory: TopicCategory? = nil
    @State private var selectedLevel: ProficiencyLevel? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search topics", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _ in
                            viewModel.filterTopics(by: selectedCategory, level: selectedLevel)
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            viewModel.filterTopics(by: selectedCategory, level: selectedLevel)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                            viewModel.filterTopics(by: nil, level: selectedLevel)
                        }
                        
                        ForEach(TopicCategory.allCases) { category in
                            CategoryFilterButton(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                                viewModel.filterTopics(by: category, level: selectedLevel)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Level filters
                HStack(spacing: 12) {
                    LevelFilterButton(level: nil, selectedLevel: selectedLevel) {
                        selectedLevel = nil
                        viewModel.filterTopics(by: selectedCategory, level: nil)
                    }
                    
                    ForEach(ProficiencyLevel.allCases) { level in
                        LevelFilterButton(level: level, selectedLevel: selectedLevel) {
                            selectedLevel = level
                            viewModel.filterTopics(by: selectedCategory, level: level)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Topics list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredTopics) { topic in
                            NavigationLink(destination: ConversationView(topic: topic)) {
                                TopicListItemView(topic: topic)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Topics", displayMode: .large)
        }
    }
}

// CategoryFilterButton moved to Shared/FilterComponents.swift

// LevelFilterButton moved to Shared/FilterComponents.swift

struct TopicListItemView: View {
    let topic: Topic
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colorFromString(topic.iconBackgroundColor))
                    .frame(width: 50, height: 50)
                
                Image(systemName: topic.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(topic.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text(topic.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(topic.level.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(levelBackgroundColor(for: topic.level))
                        .foregroundColor(levelTextColor(for: topic.level))
                        .cornerRadius(8)
                }
            }
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

#Preview {
    TopicsView()
}