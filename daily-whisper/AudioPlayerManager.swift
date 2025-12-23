//
//  AudioPlayerManager.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayerManager: NSObject, ObservableObject {
    
    @Published var isPlaying = false
    @Published var currentEntryID: UUID?
    @Published var playbackErrorMessage: String?
    
    // Referencia opcional al recorder para coordinar estados
    weak var recorder: AudioRecorderManager?
    
    private var player: AVAudioPlayer?
    
    func play(entry: AudioEntry) {
        // Bloquear reproducción si se está grabando
        if recorder?.isRecording == true {
            print("⛔️ No se puede reproducir mientras se graba.")
            return
        }
        
        guard let storedPath = entry.fileURL else {
            postError("Ruta de audio inválida.")
            return
        }
        
        guard let url = normalizeURL(from: storedPath) else {
            postError("No se pudo construir la URL del audio.")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Archivo no existe en disco:", url.path)
            postError("El archivo de audio no se encuentra en el dispositivo.")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
            
            currentEntryID = entry.id
            isPlaying = true
            
        } catch {
            print("❌ Error playing audio:", error)
            postError("No se pudo reproducir el audio.")
            stop()
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentEntryID = nil
    }
    
    func toggle(entry: AudioEntry) {
        if currentEntryID == entry.id && isPlaying {
            stop()
        } else {
            stop()
            play(entry: entry)
        }
    }
    
    // MARK: - URL Normalization
    private func normalizeURL(from storedPath: String) -> URL? {
        // Casos:
        // 1) "file:///..." -> URL(string:)
        // 2) Ruta absoluta sin esquema -> URL(fileURLWithPath:)
        // 3) Intento de fallback si el primer parse falla
        if storedPath.hasPrefix("file://") {
            if let url = URL(string: storedPath) {
                return url
            }
            // Fallback: intentar quitar el esquema si algo raro pasa
            let trimmed = storedPath.replacingOccurrences(of: "file://", with: "")
            return URL(fileURLWithPath: "/" + trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        } else {
            // Path absoluto normal
            let url = URL(fileURLWithPath: storedPath)
            return url
        }
    }
    
    private func postError(_ message: String) {
        DispatchQueue.main.async {
            self.playbackErrorMessage = message
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.currentEntryID = nil
            self?.player = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Decode error:", error ?? NSError(domain: "AudioPlayer", code: -1))
        DispatchQueue.main.async { [weak self] in
            self?.postError("Ocurrió un error de decodificación.")
            self?.stop()
        }
    }
}
