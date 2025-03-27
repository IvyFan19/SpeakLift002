//
//  FilterComponents.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct LevelFilterButton: View {
    let level: ProficiencyLevel?
    let selectedLevel: ProficiencyLevel?
    let action: () -> Void
    
    var isSelected: Bool {
        if level == nil {
            return selectedLevel == nil
        } else {
            return level == selectedLevel
        }
    }
    
    var levelColor: Color {
        guard let level = level else { return .gray }
        switch level {
        case .beginner: return .blue
        case .intermediate: return .green
        case .advanced: return .orange
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(level?.rawValue ?? "All Levels")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? levelColor.opacity(0.1) : Color.clear)
                .foregroundColor(isSelected ? levelColor : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? levelColor.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}