//
//  OpenAIVTTService.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import Foundation
import Combine
import AVFoundation
import SwiftUI
// Import without module prefix since it's in the same target
// import Models.ChatModels

#if DEBUG
// No module prefix for DevelopmentConfig
#endif

class OpenAIVTTService {
    // MARK: - Properties
    
    private var apiKey: String = ""
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var recordingURL: URL?
    
    // Callbacks
    var onTranscriptionComplete: ((String) -> Void)?
    var onTranscriptionError: ((Error) -> Void)?
    var onRecordingProgress: ((Float) -> Void)?
    var onRecordingStarted: (() -> Void)?
    var onRecordingStopped: (() -> Void)?
    
    // State
    private var isRecording = false
    private var recordingStartTime: Date?
    private var recordingDuration: TimeInterval = 0
    
    // MARK: - Initialization
    
    init() {
        // In a real implementation, this would load the API key from secure storage
        loadAPIKey()
        setupAudioSession()
    }
    
    // MARK: - Private Methods
    
    private func loadAPIKey() {
        // First try to get API key directly (in development)
        #if DEBUG
        // Use API key from DevelopmentConfig.swift
        let devKey = DevelopmentConfig.openAIApiKey
        apiKey = devKey
        print("[OpenAIVTTService] Using development API key")
        return
        #endif
        
        // Otherwise load from user defaults (for production)
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        
        // Notify developer if API key is missing
        if apiKey.isEmpty {
            print("[OpenAIVTTService] WARNING: API Key is empty. Set it in UserDefaults with key 'openai_api_key'")
        }
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Check recording permission
            switch recordingSession?.recordPermission {
            case .granted:
                print("[OpenAIVTTService] Recording permission already granted")
            case .denied:
                print("[OpenAIVTTService] Recording permission denied")
            case .undetermined:
                print("[OpenAIVTTService] Requesting recording permission")
                recordingSession?.requestRecordPermission { granted in
                    print("[OpenAIVTTService] Recording permission \(granted ? "granted" : "denied")")
                }
            default:
                break
            }
        } catch {
            print("[OpenAIVTTService] Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recording Methods
    
    func startRecording() -> Bool {
        print("[OpenAIVTTService] Starting recording...")
        
        // Check if we're already recording
        guard !isRecording else {
            print("[OpenAIVTTService] Already recording")
            return false
        }
        
        // Check recording permission status
        guard let session = recordingSession, session.recordPermission == .granted else {
            print("[OpenAIVTTService] Recording permission not granted")
            
            // Request permission if undetermined
            if recordingSession?.recordPermission == .undetermined {
                recordingSession?.requestRecordPermission { [weak self] granted in
                    if granted {
                        // Try again after permission is granted
                        DispatchQueue.main.async {
                            _ = self?.startRecording()
                        }
                    } else {
                        print("[OpenAIVTTService] Recording permission denied")
                        let permissionError = NSError(domain: "OpenAIVTTService", 
                                                     code: -1,
                                                     userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                        self?.onTranscriptionError?(permissionError)
                    }
                }
            } else {
                // Permission was explicitly denied
                let permissionError = NSError(domain: "OpenAIVTTService", 
                                             code: -1,
                                             userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                self.onTranscriptionError?(permissionError)
            }
            
            return false
        }
        
        // Create URL for recording - use m4a instead of mp3 for better compatibility
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let recordingURL = recordingURL else {
            print("[OpenAIVTTService] Failed to create recording URL")
            return false
        }
        
        print("[OpenAIVTTService] Recording to: \(recordingURL.path)")
        
        do {
            // Ensure the audio session is properly configured before recording
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Configure recording settings for AAC format (more reliable than MP3)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]
            
            // Create and start recording
            print("[OpenAIVTTService] Creating audio recorder with settings: \(settings)")
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = nil
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                isRecording = true
                recordingStartTime = Date()
                
                // Start monitoring recording levels
                startRecordingMonitoring()
                
                // Notify that recording has started
                DispatchQueue.main.async {
                    self.onRecordingStarted?()
                }
                
                return true
            } else {
                print("[OpenAIVTTService] Failed to start recording - recorder didn't start")
                return false
            }
        } catch {
            print("[OpenAIVTTService] Error starting recording: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.onTranscriptionError?(error)
            }
            
            return false
        }
    }
    
    private func startRecordingMonitoring() {
        // Create a timer to update recording progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording, let recorder = self.audioRecorder else {
                timer.invalidate()
                return
            }
            
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            let normalizedPower = (averagePower + 160) / 160 // Normalize from -160dB to 0dB
            
            DispatchQueue.main.async {
                self.onRecordingProgress?(normalizedPower)
            }
        }
    }
    
    func stopRecording() {
        guard isRecording, let recorder = audioRecorder else {
            print("[OpenAIVTTService] No active recording to stop")
            return
        }
        
        // Calculate recording duration
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        // Stop recording
        recorder.stop()
        isRecording = false
        
        // Notify that recording has stopped
        DispatchQueue.main.async {
            self.onRecordingStopped?()
        }
        
        // Process the recording
        if let url = recordingURL {
            transcribeAudio(url: url)
        } else {
            print("[OpenAIVTTService] No recording URL available")
        }
    }
    
    // MARK: - Transcription Methods
    
    private func transcribeAudio(url: URL) {
        // Check if API key is available
        if apiKey.isEmpty {
            let error = NSError(domain: "OpenAIVTTService", 
                               code: 401, 
                               userInfo: [NSLocalizedDescriptionKey: "API Key not set. Please set your OpenAI API key."])
            
            DispatchQueue.main.async {
                self.onTranscriptionError?(error)
            }
            
            return
        }
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            print("[OpenAIVTTService] Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form body
        var data = Data()
        
        // Add model parameter
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file parameter
        do {
            let audioData = try Data(contentsOf: recordingURL!)
            
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            print("[OpenAIVTTService] Error reading audio file: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.onTranscriptionError?(error)
            }
            
            return
        }
        
        // Close the form
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set request body
        request.httpBody = data
        
        // Send request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Handle network error
            if let error = error {
                print("[OpenAIVTTService] Network error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self?.onTranscriptionError?(error)
                }
                
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("[OpenAIVTTService] HTTP status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain: "OpenAIVTTService",
                                             code: httpResponse.statusCode,
                                             userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
                    
                    if let data = data, let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorJson["error"] as? [String: Any],
                       let message = errorMessage["message"] as? String {
                        print("[OpenAIVTTService] API error: \(message)")
                    }
                    
                    DispatchQueue.main.async {
                        self?.onTranscriptionError?(statusError)
                    }
                    
                    return
                }
            }
            
            // Parse response
            guard let data = data else {
                print("[OpenAIVTTService] No data received")
                
                let noDataError = NSError(domain: "OpenAIVTTService",
                                         code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "No data received from API"])
                
                DispatchQueue.main.async {
                    self?.onTranscriptionError?(noDataError)
                }
                
                return
            }
            
            do {
                // Parse JSON response
                let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                let transcribedText = response.text
                
                print("[OpenAIVTTService] Transcription successful: \"\(transcribedText)\"")
                
                DispatchQueue.main.async {
                    self?.onTranscriptionComplete?(transcribedText)
                }
            } catch {
                print("[OpenAIVTTService] JSON parsing error: \(error.localizedDescription)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[OpenAIVTTService] Response data: \(responseString)")
                }
                
                DispatchQueue.main.async {
                    self?.onTranscriptionError?(error)
                }
            }
        }
        
        task.resume()
    }
}

// Using TranscriptionResponse model from ChatModels.swift

// MARK: - Preview Helper

#if DEBUG
extension OpenAIVTTService {
    static func previewService() -> OpenAIVTTService {
        let service = OpenAIVTTService()
        
        // Override methods for preview
        service.onTranscriptionComplete = { _ in }
        service.onTranscriptionError = { _ in }
        
        return service
    }
}
#endif 