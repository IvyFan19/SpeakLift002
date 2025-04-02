//
//  OpenAISpeakingService.swift
//  SpeakLiftApp-002
//
//  Created on 4/2/25.
//

import Foundation
import Combine

class OpenAISpeakingService {
    // MARK: - Properties
    
    private var apiKey: String = ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"
    
    // Callbacks
    var onResponseReceived: ((String) -> Void)?
    var onRequestError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        loadAPIKey()
    }
    
    // MARK: - Private Methods
    
    private func loadAPIKey() {
        // First try to get API key directly (in development)
        #if DEBUG
        // Use API key from DevelopmentConfig.swift
        let devKey = DevelopmentConfig.openAIApiKey
        apiKey = devKey
        print("[OpenAISpeakingService] Using development API key")
        return
        #endif
        
        // Otherwise load from user defaults (for production)
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        
        // Notify developer if API key is missing
        if apiKey.isEmpty {
            print("[OpenAISpeakingService] WARNING: API Key is empty. Set it in UserDefaults with key 'openai_api_key'")
        }
    }
    
    // MARK: - Public Methods
    
    func sendMessage(messages: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        // Check if API key is available
        if apiKey.isEmpty {
            let error = NSError(domain: "OpenAISpeakingService", 
                               code: 401, 
                               userInfo: [NSLocalizedDescriptionKey: "API Key not set. Please set your OpenAI API key."])
            print("[OpenAISpeakingService] ERROR: API key is empty")
            completion(.failure(error))
            return
        }
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            let error = NSError(domain: "OpenAISpeakingService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
            print("[OpenAISpeakingService] ERROR: Invalid API URL")
            completion(.failure(error))
            return
        }
        
        print("[OpenAISpeakingService] Preparing request to: \(baseURL) with model: \(model)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Log the messages being sent (without sensitive content)
        print("[OpenAISpeakingService] Sending \(messages.count) messages to OpenAI")
        for (index, message) in messages.enumerated() {
            print("[OpenAISpeakingService] Message \(index): role=\(message.role), content length=\(message.content.count)")
        }
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        // Convert request body to JSON data
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("[OpenAISpeakingService] Request body prepared successfully")
        } catch {
            print("[OpenAISpeakingService] Error creating request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Send request
        print("[OpenAISpeakingService] Sending request to OpenAI API...")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                print("[OpenAISpeakingService] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Log response status
            if let httpResponse = response as? HTTPURLResponse {
                print("[OpenAISpeakingService] HTTP response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain: "OpenAISpeakingService",
                                             code: httpResponse.statusCode,
                                             userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
                    
                    if let data = data, let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("[OpenAISpeakingService] Error response: \(errorJson)")
                        
                        if let errorMessage = errorJson["error"] as? [String: Any],
                           let message = errorMessage["message"] as? String {
                            print("[OpenAISpeakingService] API error message: \(message)")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(.failure(statusError))
                    }
                    
                    return
                }
            }
            
            // Parse response
            guard let data = data else {
                print("[OpenAISpeakingService] No data received from API")
                let noDataError = NSError(domain: "OpenAISpeakingService",
                                         code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "No data received from API"])
                
                DispatchQueue.main.async {
                    completion(.failure(noDataError))
                }
                
                return
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("[OpenAISpeakingService] Raw response: \(responseString)")
            }
            
            do {
                // Parse JSON response
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChatResponse.self, from: data)
                
                if let messageContent = response.choices.first?.message.content {
                    print("[OpenAISpeakingService] Response received successfully. Content length: \(messageContent.count)")
                    
                    DispatchQueue.main.async {
                        completion(.success(messageContent))
                    }
                } else {
                    print("[OpenAISpeakingService] Response parsing issue: No message content found")
                    let emptyResponseError = NSError(domain: "OpenAISpeakingService",
                                                   code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Received empty response from API"])
                    
                    DispatchQueue.main.async {
                        completion(.failure(emptyResponseError))
                    }
                }
            } catch {
                print("[OpenAISpeakingService] JSON parsing error: \(error.localizedDescription)")
                
                // Attempt to parse the response as a different structure to diagnose the issue
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[OpenAISpeakingService] Response structure: \(jsonObject.keys)")
                    
                    // Try to extract the message directly from the JSON
                    if let choices = jsonObject["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: String],
                       let content = message["content"] {
                        print("[OpenAISpeakingService] Successfully extracted content manually")
                        
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        print("[OpenAISpeakingService] Request sent")
    }
    
    /// Sends a conversational message to OpenAI with instructions to avoid grammar correction
    func sendConversationalMessage(userMessage: String, previousMessages: [ChatMessage] = [], completion: @escaping (Result<String, Error>) -> Void) {
        print("[OpenAISpeakingService] Preparing conversational message")
        
        // Create message history starting with a system instruction
        var messages: [ChatMessage] = [
            ChatMessage(role: "system", content: "You are a helpful conversation partner. Focus on engaging with the user's ideas and continuing the conversation naturally. Keep responses concise and direct. Do not correct grammar or provide language feedback - just have a natural conversation.")
        ]
        
        // Add previous conversation context
        messages.append(contentsOf: previousMessages)
        
        // Add the latest user message
        messages.append(ChatMessage(role: "user", content: userMessage))
        
        print("[OpenAISpeakingService] Sending conversational message with \(messages.count) messages")
        
        // Send the request
        sendMessage(messages: messages, completion: completion)
    }
}

// MARK: - Preview Helper

#if DEBUG
extension OpenAISpeakingService {
    static func previewService() -> OpenAISpeakingService {
        let service = OpenAISpeakingService()
        
        // Override methods for preview
        service.onResponseReceived = { _ in }
        service.onRequestError = { _ in }
        
        return service
    }
}
#endif 