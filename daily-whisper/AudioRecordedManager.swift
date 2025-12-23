//
//  AudioRecordedManager.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import AVFoundation
import Combine

final class AudioRecorderManager: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0
    
    // Referencia opcional al player para coordinar estados
    weak var player: AudioPlayerManager?
    
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    
    // Usar AppConfig para la duración máxima
    var maxDuration: TimeInterval {
        AppConfig.shared.audio.maxRecordingDuration
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Mic permission denied")
            }
        }
    }
    
    func startRecording() throws -> URL {
        // Bloquear grabación si se está reproduciendo
        if player?.isPlaying == true {
            print("⛔️ No se puede grabar mientras se reproduce.")
            throw NSError(domain: "AudioRecorderManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se puede grabar mientras se reproduce audio."])
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker]
        )
        try session.setActive(true)
        
        let fileURL = Self.generateFileURL()
        
        // Settings desde AppConfig
        let cfg = AppConfig.shared.audio
        let settings: [String: Any] = [
            AVFormatIDKey: Int(cfg.formatID),
            AVSampleRateKey: cfg.sampleRate,
            AVNumberOfChannelsKey: cfg.numberOfChannels,
            AVEncoderAudioQualityKey: cfg.encoderQuality.rawValue
        ]
        
        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.record()
        
        isRecording = true
        currentTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentTime += 0.1
                if self.currentTime >= self.maxDuration {
                    self.stopRecording()
                }
            }
        }
        
        return fileURL
    }
    
    func stopRecording() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        isRecording = false
    }
    
    private static func generateFileURL() -> URL {
        let filename = UUID().uuidString + ".m4a"
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
}

