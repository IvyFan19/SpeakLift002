//
//  BookmarksView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

import SwiftUI

// Import shared components from FilterComponents

struct BookmarksView: View {
    @State private var searchText = ""
    @State private var selectedCategory: BookmarkCategory? = nil
    @State private var bookmarkedMessages: [BookmarkedMessage] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search bookmarks", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
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
                        }
                        
                        ForEach(BookmarkCategory.allCases) { category in
                            CategoryFilterButton(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Bookmarks list
                if filteredBookmarks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No bookmarks yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Bookmark messages during conversations to save them here")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredBookmarks) { bookmark in
                                BookmarkItemView(bookmark: bookmark)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Bookmarks", displayMode: .large)
        }
        .onAppear {
            // In a real implementation, this would load bookmarks from storage
            loadExampleBookmarks()
        }
    }
    
    private var filteredBookmarks: [BookmarkedMessage] {
        var result = bookmarkedMessages
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    private func loadExampleBookmarks() {
        bookmarkedMessages = [
            BookmarkedMessage(
                id: UUID(),
                content: "こんにちは (Konnichiwa) - Hello",
                timestamp: Date().addingTimeInterval(-86400 * 2),
                category: .phrases,
                conversationTitle: "Japanese Travel Phrases"
            ),
            BookmarkedMessage(
                id: UUID(),
                content: "The people were friendly",
                timestamp: Date().addingTimeInterval(-86400 * 5),
                category: .corrections,
                conversationTitle: "Paris Travel Experience",
                originalText: "The people was friendly",
                explanation: "'People' is a plural noun, so it requires the plural verb form 'were' instead of the singular 'was'."
            ),
            BookmarkedMessage(
                id: UUID(),
                content: "I'd like to order a coffee, please.",
                timestamp: Date().addingTimeInterval(-86400 * 1),
                category: .phrases,
                conversationTitle: "Cafe Conversations"
            ),
            BookmarkedMessage(
                id: UUID(),
                content: "Could you please tell me how to get to the museum?",
                timestamp: Date().addingTimeInterval(-86400 * 3),
                category: .phrases,
                conversationTitle: "Asking for Directions"
            ),
            BookmarkedMessage(
                id: UUID(),
                content: "I have been studying English for three years",
                timestamp: Date().addingTimeInterval(-86400 * 4),
                category: .corrections,
                conversationTitle: "Language Learning",
                originalText: "I have study English for three years",
                explanation: "Use the present perfect continuous tense ('have been studying') for an action that started in the past and continues to the present."
            )
        ]
    }
}

// CategoryFilterButton moved to Shared/FilterComponents.swift

struct BookmarkItemView: View {
    let bookmark: BookmarkedMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(bookmark.conversationTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(bookmark.content)
                .font(.body)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            if bookmark.category == .corrections, let originalText = bookmark.originalText, let explanation = bookmark.explanation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Original: \(originalText)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 20)
                }
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    // Play audio
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                }
                .padding(8)
                
                Button(action: {
                    // Share
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
                .padding(8)
                
                Button(action: {
                    // Remove from bookmarks
                }) {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(.red)
                }
                .padding(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var categoryIcon: String {
        switch bookmark.category {
        case .phrases:
            return "text.bubble"
        case .corrections:
            return "checkmark"
        case .vocabulary:
            return "book"
        }
    }
    
    private var categoryColor: Color {
        switch bookmark.category {
        case .phrases:
            return .blue
        case .corrections:
            return .orange
        case .vocabulary:
            return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: bookmark.timestamp)
    }
}

// MARK: - Models

enum BookmarkCategory: String, CaseIterable, Identifiable {
    case phrases = "Phrases"
    case corrections = "Corrections"
    case vocabulary = "Vocabulary"
    
    var id: String { self.rawValue }
}

struct BookmarkedMessage: Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let category: BookmarkCategory
    let conversationTitle: String
    let originalText: String?
    let explanation: String?
    
    init(id: UUID = UUID(), content: String, timestamp: Date, category: BookmarkCategory, conversationTitle: String, originalText: String? = nil, explanation: String? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.category = category
        self.conversationTitle = conversationTitle
        self.originalText = originalText
        self.explanation = explanation
    }
}

// MARK: - Preview

#Preview {
    BookmarksView()
}