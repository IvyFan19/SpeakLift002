//
//  SettingsView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey = ""
    @State private var proficiencyLevel: ProficiencyLevel = .intermediate
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileSettingsView()) {
                        SettingsRowView(iconName: "person.fill", iconBackground: .blue, title: "Profile")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRowView(iconName: "bell.fill", iconBackground: .red, title: "Notifications")
                    }
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: ProficiencyLevelSettingsView(selectedLevel: $proficiencyLevel)) {
                        SettingsRowView(iconName: "chart.bar.fill", iconBackground: .green, title: "Proficiency Level")
                    }
                    
                    NavigationLink(destination: Text("Voice Settings")) {
                        SettingsRowView(iconName: "waveform", iconBackground: .purple, title: "Voice Settings")
                    }
                    
                    NavigationLink(destination: Text("Appearance")) {
                        SettingsRowView(iconName: "paintbrush.fill", iconBackground: .orange, title: "Appearance")
                    }
                }
                
                // API Settings Section
                Section(header: Text("API Settings")) {
                    NavigationLink(destination: APIKeySettingsView(apiKey: $apiKey)) {
                        SettingsRowView(iconName: "key.fill", iconBackground: .gray, title: "API Key")
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink(destination: Text("Help Center")) {
                        SettingsRowView(iconName: "questionmark.circle.fill", iconBackground: .blue, title: "Help Center")
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        SettingsRowView(iconName: "lock.fill", iconBackground: .gray, title: "Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        SettingsRowView(iconName: "doc.text.fill", iconBackground: .gray, title: "Terms of Service")
                    }
                }
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    Button(action: {
                        // Clear conversation history
                    }) {
                        SettingsRowView(iconName: "trash.fill", iconBackground: .red, title: "Clear Conversation History")
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        SettingsRowView(iconName: "xmark.circle.fill", iconBackground: .red, title: "Delete Account")
                    }
                }
                
                // App Info Section
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Settings", displayMode: .large)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    // Handle account deletion
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct SettingsRowView: View {
    let iconName: String
    let iconBackground: Color
    let title: String
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(iconBackground.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .foregroundColor(iconBackground)
            }
            
            Text(title)
                .padding(.leading, 8)
        }
    }
}

struct ProfileSettingsView: View {
    @State private var name = User.example.name
    @State private var email = User.example.email
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
            }
            
            Section {
                Button("Save Changes") {
                    // Save changes
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .navigationBarTitle("Profile", displayMode: .inline)
    }
}

struct NotificationSettingsView: View {
    @State private var dailyReminders = true
    @State private var practiceReminders = true
    @State private var reminderTime = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Notification Preferences")) {
                Toggle("Daily Reminders", isOn: $dailyReminders)
                Toggle("Practice Reminders", isOn: $practiceReminders)
            }
            
            Section(header: Text("Reminder Time")) {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
        .navigationBarTitle("Notifications", displayMode: .inline)
    }
}

struct ProficiencyLevelSettingsView: View {
    @Binding var selectedLevel: ProficiencyLevel
    
    var body: some View {
        Form {
            Section(header: Text("Select Your Proficiency Level")) {
                ForEach(ProficiencyLevel.allCases) { level in
                    Button(action: {
                        selectedLevel = level
                    }) {
                        HStack {
                            Text(level.rawValue)
                            Spacer()
                            if selectedLevel == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section(header: Text("About Proficiency Levels")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beginner")
                        .font(.headline)
                    Text("For those just starting to learn English or with basic knowledge.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intermediate")
                        .font(.headline)
                    Text("For those who can communicate in English but want to improve fluency.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced")
                        .font(.headline)
                    Text("For those who are fluent but want to refine their skills and expand vocabulary.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationBarTitle("Proficiency Level", displayMode: .inline)
    }
}

struct APIKeySettingsView: View {
    @Binding var apiKey: String
    @State private var isEditing = false
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key"), footer: Text("Your API key is stored securely on your device and is used to access the OpenAI services.")) {
                if isEditing {
                    TextField("Enter API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    Text(apiKey.isEmpty ? "No API key set" : "API key is set")
                }
            }
            
            Section {
                Button(isEditing ? "Save" : "Edit") {
                    isEditing.toggle()
                }
            }
        }
    }
}