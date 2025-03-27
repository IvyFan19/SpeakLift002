//
//  Topic.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation

struct Topic: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let level: ProficiencyLevel
    let iconName: String
    let iconBackgroundColor: String
    let category: TopicCategory
    
    init(id: UUID = UUID(), title: String, description: String, level: ProficiencyLevel, iconName: String, iconBackgroundColor: String, category: TopicCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.level = level
        self.iconName = iconName
        self.iconBackgroundColor = iconBackgroundColor
        self.category = category
    }
}

enum TopicCategory: String, CaseIterable, Identifiable {
    case daily = "Daily Life"
    case travel = "Travel"
    case business = "Business"
    case culture = "Culture"
    case technology = "Technology"
    case education = "Education"
    
    var id: String { self.rawValue }
}