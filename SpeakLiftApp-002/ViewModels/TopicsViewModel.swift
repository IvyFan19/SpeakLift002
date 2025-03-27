//
//  TopicsViewModel.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation

class TopicsViewModel: ObservableObject {
    @Published var recommendedTopics: [Topic] = []
    @Published var allTopics: [Topic] = []
    @Published var filteredTopics: [Topic] = []
    @Published var searchText: String = ""
    
    init() {
        loadTopics()
    }
    
    private func loadTopics() {
        // In a real app, this would load from a database or API
        // For now, we'll create some example topics
        let topics = [
            Topic(
                title: "Travel Plans",
                description: "Discuss your upcoming travel plans and get advice on destinations.",
                level: .intermediate,
                iconName: "airplane",
                iconBackgroundColor: "blue",
                category: .travel
            ),
            Topic(
                title: "Job Interview",
                description: "Practice common job interview questions and professional responses.",
                level: .advanced,
                iconName: "briefcase",
                iconBackgroundColor: "purple",
                category: .business
            ),
            Topic(
                title: "Daily Routine",
                description: "Talk about your daily activities and learn useful everyday phrases.",
                level: .beginner,
                iconName: "clock",
                iconBackgroundColor: "green",
                category: .daily
            ),
            Topic(
                title: "Technology Trends",
                description: "Discuss the latest technology trends and expand your tech vocabulary.",
                level: .intermediate,
                iconName: "desktopcomputer",
                iconBackgroundColor: "orange",
                category: .technology
            ),
            Topic(
                title: "Cultural Differences",
                description: "Explore cultural differences and learn to express your opinions.",
                level: .advanced,
                iconName: "globe",
                iconBackgroundColor: "red",
                category: .culture
            ),
            Topic(
                title: "Restaurant Ordering",
                description: "Practice ordering food and making special requests at restaurants.",
                level: .beginner,
                iconName: "fork.knife",
                iconBackgroundColor: "orange",
                category: .daily
            )
        ]
        
        allTopics = topics
        recommendedTopics = Array(topics.prefix(3))
        filteredTopics = topics
    }
    
    func filterTopics(by category: TopicCategory? = nil, level: ProficiencyLevel? = nil) {
        var filtered = allTopics
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let level = level {
            filtered = filtered.filter { $0.level == level }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.lowercased().contains(searchText.lowercased()) || 
                                         $0.description.lowercased().contains(searchText.lowercased()) }
        }
        
        filteredTopics = filtered
    }
}