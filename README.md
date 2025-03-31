# SpeakLift

SpeakLift is an iOS application designed to help users practice conversational English with real-time grammar correction. The app leverages OpenAI's ChatGPT API to provide an interactive language learning experience.

## Features

- **Real-time Conversations**: Practice speaking English with an AI conversation partner
- **Grammar Correction**: Receive instant feedback on your grammar and pronunciation
- **Topic-based Learning**: Choose from various conversation topics based on your proficiency level
- **Bookmarks**: Save important corrections and phrases for later review

## Requirements

- macOS with Xcode 15 or later
- iOS 16.0+ target device or simulator
- OpenAI API key for ChatGPT integration

## Installation

1. Clone the repository to your local machine:
   ```
   git clone https://github.com/IvyFan19/SpeakLift002.git
   ```

2. Open the project in Xcode:
   ```
   cd SpeakLiftApp-002
   ```

3. Configure your OpenAI API key:
   - Create a `Config` folder in the project: `mkdir Config`
   - Add a file named `DevelopmentConfig.swift` with the following content:
   ```swift
   struct DevelopmentConfig {
       static let openAIApiKey = "YOUR_ACTUAL_API_KEY_HERE"
   }
   ```
   - Replace `YOUR_ACTUAL_API_KEY_HERE` with your OpenAI API key

## Running the App
1. Go back to the project root:
1. Select your target device or simulator in Xcode
2. Click the Run button (▶️) or press `Cmd+R`
3. The app will build and launch on your selected device

## Usage Guide

### Home Screen
The main dashboard shows your learning progress and suggested practice sessions.

### Topics
Browse and select conversation topics organized by difficulty level and category.

### Conversation
Start a conversation by selecting a topic. Speak into your device and receive real-time transcription and corrections.

### Bookmarks
Access saved phrases and corrections for review.

### Settings
Configure app preferences, manage your profile, and adjust learning parameters.

## Technical Architecture

SpeakLift is built using SwiftUI and follows a MVVM architecture pattern:

- **Models**: Data structures for topics, users, and conversations
- **Views**: SwiftUI interface components
- **ViewModels**: Business logic connecting models and views
- **Services**: API integration with OpenAI

## License
MIT License

## Contact
xinwei.fan19@gmail.com