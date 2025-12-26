//
//  AppConfig.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import AVFoundation
import CoreData

final class AppConfig {
    static let shared = AppConfig()
    private init() {
        // Sincronizar audio.maxEntriesPerDay con la policy actual al inicio
        audio.maxEntriesPerDay = policy.maxEntriesPerDay
    }
    
    // MARK: - Roles y políticas
    enum UserRole: String, CaseIterable {
        case normal
        case pro
    }
    
    struct Policy {
        var maxEntriesPerDay: Int
        var retentionDays: Int
    }
    
    struct Subscription {
        var role: UserRole = .normal
        
        var policy: Policy {
            switch role {
            case .normal:
                return Policy(
                    maxEntriesPerDay: 1,
                    retentionDays: 7
                )
            case .pro:
                return Policy(
                    maxEntriesPerDay: 5,
                    retentionDays: 30
                )
            }
        }
    }
    
    // Config actual de suscripción
    var subscription = Subscription() {
        didSet {
            // Mantener audio sincronizado si el rol cambia
            audio.maxEntriesPerDay = subscription.policy.maxEntriesPerDay
        }
    }
    
    // Acceso rápido a la política vigente
    var policy: Policy { subscription.policy }
    
    // MARK: - Audio
    struct Audio {
        // Límite de duración de grabación (segundos)
        var maxRecordingDuration: TimeInterval = 30
        
        // Cantidad máxima de audios permitidos por día
        // Este valor lo sincronizamos con la policy para evitar tocar múltiples sitios
        var maxEntriesPerDay: Int = 15
        
        // Parámetros de grabación (puedes ajustarlos si lo necesitas)
        var formatID: UInt32 = kAudioFormatMPEG4AAC
        var sampleRate: Double = 44_100
        var numberOfChannels: Int = 1
        var encoderQuality: AVAudioQuality = .high
    }
    
    // MARK: - UI
    struct UI {
        // Color de acento global de la app (cámbialo aquí para ajustar rápido)
        var accentColor: Color = .mint
        
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

// MARK: - Retención de audios
extension AppConfig {
    /// Elimina entradas de Core Data (y sus archivos en disco) más antiguas que retentionDays según la policy actual.
    /// Debe llamarse en un contexto adecuado (por ejemplo, al entrar en foreground).
    func cleanupOldEntries(context: NSManagedObjectContext) {
        let days = policy.retentionDays
        guard days > 0 else { return } // 0 o negativo => sin retención
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date().addingTimeInterval(-Double(days) * 86400)
        
        let fetch: NSFetchRequest<AudioEntry> = AudioEntry.fetchRequest()
        fetch.predicate = NSPredicate(format: "date < %@", cutoff as NSDate)
        
        do {
            let oldEntries = try context.fetch(fetch)
            guard !oldEntries.isEmpty else { return }
            
            for entry in oldEntries {
                // Borrar archivo físico si existe
                if let storedPath = entry.fileURL {
                    let url: URL
                    if storedPath.hasPrefix("file://"), let u = URL(string: storedPath) {
                        url = u
                    } else {
                        url = URL(fileURLWithPath: storedPath)
                    }
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
                // Borrar de Core Data
                context.delete(entry)
            }
            try context.save()
        } catch {
            print("Retention cleanup error: \(error)")
        }
    }
}
