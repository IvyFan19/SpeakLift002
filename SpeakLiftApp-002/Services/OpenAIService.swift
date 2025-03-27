//
//  OpenAIService.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation
import Combine
import AVFoundation
import SwiftUI

// 导入本地配置
#if DEBUG
import Foundation
#endif

class OpenAIService {
    private var apiKey: String = ""
    private let baseURL = "https://api.openai.com/v1"
    private let realtimeURL = "wss://api.openai.com/v1/audio/transcriptions"
    
    private var realtimeSession: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    var onTranscriptionUpdate: ((String) -> Void)?
    var onTranscriptionComplete: ((String) -> Void)?
    var onTranscriptionError: ((Error) -> Void)?
    
    private var isRecording = false
    private var accumulatedTranscription = ""
    private var isConnectionEstablished = false
    
    init() {
        // In a real implementation, this would load the API key from secure storage
        loadAPIKey()
        setupAudioEngine()
    }
    
    private func loadAPIKey() {
        // 首先尝试从开发配置中获取 API 密钥（在开发阶段使用）
        #if DEBUG
        let devKey = DevelopmentConfig.openAIApiKey
        if !devKey.isEmpty && devKey != "YOUR_ACTUAL_API_KEY_HERE" {
            apiKey = devKey
            print("Using development API key")
            return
        }
        #endif
        
        // 如果没有开发密钥或者不是调试模式，则从用户默认设置中加载
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        
        // 提示开发者设置 API 密钥
        if apiKey.isEmpty {
            print("WARNING: API Key is empty. Set it in UserDefaults with key 'openai_api_key' or in DevelopmentConfig.swift")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }
    
    // MARK: - Realtime Audio Transcription
    
    func startRealtimeTranscription() {
        guard !isRecording else { return }
        
        // Check if API key is available
        if apiKey.isEmpty {
            let error = NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set. Please set your OpenAI API key."])
            onTranscriptionError?(error)
            return
        }
        
        // Create a new audio engine each time to avoid format issues
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else {
            let error = NSError(domain: "OpenAIService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize audio engine"])
            onTranscriptionError?(error)
            return
        }
        
        isRecording = true
        accumulatedTranscription = ""
        isConnectionEstablished = false
        
        // 设置并连接 WebSocket
        setupRealtimeWebSocketConnection()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Get the format from the input node
            let format = inputNode.outputFormat(forBus: 0)
            
            // Validate the format
            guard format.sampleRate > 0 && format.channelCount > 0 else {
                let error = NSError(domain: "OpenAIService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
                onTranscriptionError?(error)
                isRecording = false
                return
            }
            
            // 等待连接建立后再安装 tap
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.isRecording else { return }
                
                // Install tap on the audio input node to capture audio data
                inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                    guard let self = self, self.isRecording, self.isConnectionEstablished else { return }
                    
                    // Convert buffer to PCM data
                    if let audioData = self.prepareAudioDataFromBuffer(buffer, format: format) {
                        self.sendAudioChunk(audioData)
                    }
                }
                
                // Start the audio engine
                audioEngine.prepare()
                do {
                    try audioEngine.start()
                    
                    // 通知用户录音已开始
                    DispatchQueue.main.async {
                        self.onTranscriptionUpdate?("Connecting to OpenAI...")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.onTranscriptionError?(error)
                        self.stopRealtimeTranscription()
                    }
                }
            }
            
        } catch {
            onTranscriptionError?(error)
            stopRealtimeTranscription()
        }
    }
    
    private func setupRealtimeWebSocketConnection() {
        // 构建 URL 和请求
        guard let url = URL(string: realtimeURL) else { 
            onTranscriptionError?(NSError(domain: "OpenAIService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        // 添加必要的头信息
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // 更新内容类型 - 根据 OpenAI 文档
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        
        // 打印连接信息 (仅用于调试)
        print("Connecting to WebSocket: \(realtimeURL)")
        print("API Key prefix: \(String(apiKey.prefix(5)))...")
        
        // 创建 WebSocket 任务
        let session = URLSession(configuration: .default)
        realtimeSession = session.webSocketTask(with: request)
        
        // 设置消息接收处理
        receiveMessages()
        
        // 先启动连接，等待连接建立后再发送配置消息
        realtimeSession?.resume()
        
        // 延迟发送配置消息，确保连接已建立
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendConfigMessage()
        }
    }
    
    private func sendConfigMessage() {
        // 根据文档发送初始配置消息
        let configMessage: [String: Any] = [
            "model": "whisper-1",
            "language": "en", // 或者可以设置为其他语言，如 "zh" 表示中文
            "format": "json", // 修改为正确的参数名称
            "temperature": 0.0 // 使用精确的浮点数值
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: configMessage),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            onTranscriptionError?(NSError(domain: "OpenAIService", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to create config message"]))
            return
        }
        
        print("Sending config: \(jsonString)")
        
        realtimeSession?.send(.string(jsonString)) { [weak self] error in
            if let error = error {
                print("Failed to send config: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.onTranscriptionError?(error)
                    self?.stopRealtimeTranscription()
                }
            } else {
                print("Config sent successfully")
                DispatchQueue.main.async {
                    self?.isConnectionEstablished = true
                    self?.onTranscriptionUpdate?("Connection established. Start speaking...")
                }
            }
        }
    }
    
    private func receiveMessages() {
        realtimeSession?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleWebSocketData(data)
                    
                case .string(let string):
                    self.handleWebSocketString(string)
                    
                @unknown default:
                    break
                }
                
                // 继续接收消息
                if self.isRecording {
                    self.receiveMessages()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onTranscriptionError?(error)
                    self.stopRealtimeTranscription()
                }
            }
        }
    }
    
    private func handleWebSocketData(_ data: Data) {
        // 尝试解析数据
        if let string = String(data: data, encoding: .utf8) {
            handleWebSocketString(string)
        }
    }
    
    private func handleWebSocketString(_ string: String) {
        // 解析 JSON 响应
        print("Received from WebSocket: \(string)")
        
        guard let data = string.data(using: .utf8) else { 
            print("Failed to convert string to data")
            return 
        }
        
        do {
            // 解析为 JSON
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // 检查是否有错误
                if let error = json["error"] as? [String: Any], 
                   let message = error["message"] as? String {
                    print("Error from OpenAI: \(message)")
                    let errorObj = NSError(domain: "OpenAIService", code: 1005, userInfo: [NSLocalizedDescriptionKey: message])
                    DispatchQueue.main.async {
                        self.onTranscriptionError?(errorObj)
                    }
                    return
                }
                
                // 检查是否有转录结果
                if let text = json["text"] as? String {
                    DispatchQueue.main.async {
                        if self.accumulatedTranscription.isEmpty {
                            self.accumulatedTranscription = text
                        } else {
                            // 添加空格，避免文本连在一起
                            self.accumulatedTranscription += " " + text
                        }
                        
                        print("Updated transcription: \(self.accumulatedTranscription)")
                        self.onTranscriptionUpdate?(self.accumulatedTranscription)
                    }
                } else {
                    print("No 'text' field found in response: \(json)")
                }
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    private func prepareAudioDataFromBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data? {
        guard let floatChannelData = buffer.floatChannelData else { return nil }
        
        // 获取格式信息
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        // 打印音频格式信息（仅用于调试）
        if frameLength % 1000 == 0 {  // 不要每次都打印，避免日志过多
            print("Audio format - Sample rate: \(sampleRate), Channels: \(channelCount), Frame length: \(frameLength)")
        }
        
        // 创建 PCM 数据包
        var audioData = Data()
        
        // 将浮点音频数据转换为 16 位整数
        for channel in 0..<channelCount {
            let floatData = floatChannelData[channel]
            
            for frame in 0..<frameLength {
                // 将浮点值（范围 -1.0 到 1.0）转换为 16 位整数
                let floatValue = floatData[Int(frame)]
                let intValue = Int16(floatValue * 32767)
                
                // 添加到数据中（小端格式）
                audioData.append(UInt8(intValue & 0xff))
                audioData.append(UInt8(intValue >> 8))
            }
        }
        
        return audioData
    }
    
    private func sendAudioChunk(_ audioData: Data) {
        // 每隔一定时间记录一次发送的数据量
        static var lastLog = Date()
        let now = Date()
        if now.timeIntervalSince(lastLog) > 5.0 {  // 每5秒记录一次
            print("Sending audio chunk: \(audioData.count) bytes")
            lastLog = now
        }
        
        // 发送音频数据块
        realtimeSession?.send(.data(audioData)) { [weak self] error in
            if let error = error {
                print("Error sending audio chunk: \(error.localizedDescription)")
                
                // 如果是连接已关闭的错误，不要继续尝试重新连接
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    print("WebSocket connection closed")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.onTranscriptionError?(error)
                }
            }
        }
    }
    
    func stopRealtimeTranscription() {
        guard isRecording else { return }
        
        print("Stopping realtime transcription")
        isRecording = false
        isConnectionEstablished = false
        
        // 发送终止消息
        sendTerminationMessage()
        
        // 停止音频引擎并移除 tap
        if let inputNode = inputNode {
            inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()
        
        // 关闭 WebSocket 连接
        realtimeSession?.cancel(with: .goingAway, reason: nil)
        
        // 调用完成处理程序
        onTranscriptionComplete?(accumulatedTranscription)
    }
    
    private func sendTerminationMessage() {
        // 根据文档发送终止消息
        let terminationMessage: [String: String] = ["type": "FinalTranscript"]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: terminationMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            realtimeSession?.send(.string(jsonString)) { _ in }
        }
    }
    
    // MARK: - Regular Transcription
    
    func transcribeAudio(audioData: Data) -> AnyPublisher<String, Error> {
        guard !apiKey.isEmpty else {
            return Fail(error: NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"]))
                .eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add the model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add the audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add the closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: TranscriptionResponse.self, decoder: JSONDecoder())
            .map { $0.text }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Chat API
    
    func sendMessage(messages: [ChatMessage]) -> AnyPublisher<AIResponse, Error> {
        guard !apiKey.isEmpty else {
            return Fail(error: NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"]))
                .eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return Fail(error: NSError(domain: "OpenAIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"]))
                .eraseToAnyPublisher()
        }
        
        request.httpBody = jsonData
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: ChatResponse.self, decoder: JSONDecoder())
            .map { response in
                // Extract the response content
                let content = response.choices.first?.message.content ?? ""
                
                // In a real implementation, you would parse grammar corrections from the AI response
                // For now, we'll return an empty array
                return AIResponse(content: content, corrections: [])
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Model Structs

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct AIResponse {
    let content: String
    let corrections: [GrammarCorrection]
}

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}