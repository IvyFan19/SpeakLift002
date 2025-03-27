//
//  User.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation

enum ProficiencyLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var id: String { self.rawValue }
}

struct User {
    let id: UUID
    let name: String
    let email: String
    let proficiencyLevel: ProficiencyLevel
    let streakDays: Int
    let progressToNextLevel: Double // 0.0 to 1.0
    
    // Example user for preview and development
    static let example = User(
        id: UUID(),
        name: "Sylvie",
        email: "sylvie@example.com",
        proficiencyLevel: .intermediate,
        streakDays: 5,
        progressToNextLevel: 0.75
    )
}