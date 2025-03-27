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
    @State private var tempApiKey = ""
    @State private var showSavedAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key"), footer: Text("Your API key is stored securely on your device and is used to access the OpenAI services. Get your API key from https://platform.openai.com/")) {
                if isEditing {
                    TextField("Enter API Key", text: $tempApiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                        .onAppear {
                            tempApiKey = apiKey
                        }
                } else {
                    if apiKey.isEmpty {
                        Text("No API key set")
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading) {
                            Text("API key is set")
                            Text(maskApiKey(apiKey))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(footer: Text("要使用实时语音转文字功能，您必须设置有效的 OpenAI API 密钥。这会在您使用应用时产生 API 调用费用。")) {
                if isEditing {
                    Button("Save") {
                        saveApiKey()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    Button("Cancel") {
                        isEditing = false
                        tempApiKey = apiKey
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    Button("Edit API Key") {
                        isEditing = true
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    if !apiKey.isEmpty {
                        Button("Clear API Key") {
                            clearApiKey()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            Section(header: Text("API 说明")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("如何获取 OpenAI API 密钥:")
                        .font(.headline)
                    
                    Text("1. 在浏览器中访问 https://platform.openai.com/")
                    Text("2. 注册或登录您的 OpenAI 账户")
                    Text("3. 点击右上角的个人资料图标，然后选择「View API keys」")
                    Text("4. 点击「Create new secret key」按钮")
                    Text("5. 复制生成的 API 密钥并粘贴到上面的输入框中")
                    
                    Text("注意：确保保管好您的 API 密钥，因为它与您的 OpenAI 账户和计费关联。")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationBarTitle("API Key Settings", displayMode: .inline)
        .alert(isPresented: $showSavedAlert) {
            Alert(
                title: Text("API Key Saved"),
                message: Text("Your OpenAI API key has been saved successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveApiKey() {
        // 保存 API 密钥到用户默认设置
        UserDefaults.standard.set(tempApiKey, forKey: "openai_api_key")
        apiKey = tempApiKey
        isEditing = false
        showSavedAlert = true
    }
    
    private func clearApiKey() {
        // 清除 API 密钥
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
        apiKey = ""
    }
    
    private func maskApiKey(_ key: String) -> String {
        // 遮盖 API 密钥，只显示前 4 个和最后 4 个字符
        if key.count > 8 {
            let prefix = key.prefix(4)
            let suffix = key.suffix(4)
            return "\(prefix)••••••••\(suffix)"
        } else {
            return "••••••••••••"
        }
    }
}