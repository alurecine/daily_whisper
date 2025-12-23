//
//  AppConfig.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import AVFoundation

final class AppConfig {
    static let shared = AppConfig()
    private init() {}
    
    // MARK: - Audio
    struct Audio {
        // Límite de duración de grabación (segundos)
        var maxRecordingDuration: TimeInterval = 30
        
        // Cantidad máxima de audios permitidos por día
        var maxEntriesPerDay: Int = 15
        
        // Parámetros de grabación (puedes ajustarlos si lo necesitas)
        var formatID: UInt32 = kAudioFormatMPEG4AAC
        var sampleRate: Double = 44_100
        var numberOfChannels: Int = 1
        var encoderQuality: AVAudioQuality = .high
    }
    
    // MARK: - UI
    struct UI {
        var recordButton = RecordButton()
        
        struct RecordButton {
            // Tamaño base del botón
            var size: CGFloat = 100
            
            // Colores
            var idleColor: Color = .blue
            var recordingColor: Color = .red
            
            // Animación de “respiración”
            var baseScale: CGFloat = 1.0
            var pulseScale: CGFloat = 1.12
            var pulseDuration: Double = 1.1
            
            // Halo
            var haloMinScale: CGFloat = 1.2
            var haloMaxScale: CGFloat = 1.5
            var haloMinOpacity: Double = 0.15
            var haloMaxOpacity: Double = 0.35
            var haloBlurRadius: CGFloat = 6
            
            // Botón: blur/sombra/opacidad cuando está grabando
            var recordingBlurRadius: CGFloat = 1.5
            var recordingShadowRadius: CGFloat = 10
            var recordingShadowColor: Color = Color.red.opacity(0.25)
            var idleShadowRadius: CGFloat = 6
            var idleShadowColor: Color = Color.black.opacity(0.15)
            var recordingOpacityLow: Double = 0.94
            
            // Separación con el timer u otros elementos debajo
            var bottomPadding: CGFloat = 16
        }
    }
    
    // Instancias actuales (mutables si quieres ajustar en tiempo de ejecución)
    var audio = Audio()
    var ui = UI()
}

