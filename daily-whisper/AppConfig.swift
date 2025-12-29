//
//  AppConfig.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import AVFoundation
internal import CoreData

final class AppConfig {
    static let shared = AppConfig()
    private init() {
        // Sincronizar configuración de audio con la policy actual al inicio
        audio.maxEntriesPerDay = policy.maxEntriesPerDay
        audio.maxRecordingDuration = policy.maxRecordingDuration
    }
    
    // MARK: - Roles y políticas
    enum UserRole: String, CaseIterable {
        case normal
        case pro
        case unlimited
    }
    
    struct Policy {
        var maxEntriesPerDay: Int
        var retentionDays: Int
        var maxRecordingDuration: TimeInterval
    }
    
    struct Subscription {
        var role: UserRole = .normal
        
        var policy: Policy {
            switch role {
            case .normal:
                return Policy(
                    maxEntriesPerDay: 1,
                    retentionDays: 7,
                    maxRecordingDuration: 30
                )
            case .pro:
                return Policy(
                    maxEntriesPerDay: 5,
                    retentionDays: 30,
                    maxRecordingDuration: 60
                )
            case .unlimited:
                return Policy(
                    maxEntriesPerDay: 0,
                    retentionDays: 90,
                    maxRecordingDuration: 120
                )
            }
        }
    }
    
    // Config actual de suscripción
    var subscription = Subscription() {
        didSet {
            // Mantener audio sincronizado si el rol cambia
            let p = subscription.policy
            audio.maxEntriesPerDay = p.maxEntriesPerDay
            audio.maxRecordingDuration = p.maxRecordingDuration
        }
    }
    
    // Acceso rápido a la política vigente
    var policy: Policy { subscription.policy }
    
    // MARK: - Audio
    struct Audio {
        var maxRecordingDuration: TimeInterval = 30
        var maxEntriesPerDay: Int = 15
        var formatID: UInt32 = kAudioFormatMPEG4AAC
        var sampleRate: Double = 44_100
        var numberOfChannels: Int = 1
        var encoderQuality: AVAudioQuality = .high
    }
    
    // MARK: - Emociones (Dominio)
    enum Emotion: String, CaseIterable, Identifiable {
        // Existentes
//        case agotada = "agotada"
//        case angry = "angry"
//        case charlatan = "charlatan"
//        case creative = "creative"
//        case facinada = "facinada"
//        case inlove = "inlove"
//        case suenio = "suenio"
        
        // Nuevas desde Assets/emociones
//        case adios = "adios"
        case alerta = "alerta"
        case angelical = "angelical"
        case cansado = "cansado"
        case carinioso = "carinioso"
        case contento = "contento"
        case decepcionado = "decepcionado"
        case demonio = "demonio"
//        case dinero = "dinero"
        case dormir = "dormir"
        case enamorado = "enamorado"
        case enfadado = "enfadado"
        case enfermo = "enfermo"
//        case gracioso = "gracioso"
        case hambriento = "hambriento"
        case herido = "herido"
//        case hola = "hola"
        case llorando = "llorando"
        case loca = "loca"
        case muerto = "muerto"
        case orgulloso = "orgulloso"
        case pasarPorAlto = "pasar-por-alto"
        case pensamiento = "pensamiento"
        case risa = "risa"
        case solo = "solo"
        case sorpresa = "sorpresa"
        case suspiro = "suspiro"
        case triste = "triste"
        
        var id: String { rawValue }
        
        var title: String {
            // Por ahora, mismo nombre del asset (puedes ajustar más adelante)
            switch self {
            // Existentes con títulos ya definidos
//            case .agotada: return "Agotada"
//            case .angry: return "Enojada"
//            case .charlatan: return "Charlatán"
//            case .creative: return "Creativa"
//            case .facinada: return "Fascinada"
//            case .inlove: return "Enamorada"
//            case .suenio: return "Sueño"
            // Nuevas (usar el nombre del asset tal cual)
//            case .adios: return "adios"
            case .alerta: return "alerta"
            case .angelical: return "angelical"
            case .cansado: return "cansado"
            case .carinioso: return "cariñoso"
            case .contento: return "contento"
            case .decepcionado: return "decepcionado"
            case .demonio: return "endemoniado"
//            case .dinero: return "dinero"
            case .dormir: return "dormilon"
            case .enamorado: return "enamorado"
            case .enfadado: return "enfadado"
            case .enfermo: return "enfermo"
//            case .gracioso: return "gracioso"
            case .hambriento: return "hambriento"
            case .herido: return "herido"
//            case .hola: return "hola"
            case .llorando: return "lloroso"
            case .loca: return "loco"
            case .muerto: return "muerto"
            case .orgulloso: return "orgulloso"
            case .pasarPorAlto: return "indiferente"
            case .pensamiento: return "pensante"
            case .risa: return "gracioso"
            case .solo: return "solo"
            case .sorpresa: return "sorprendido"
            case .suspiro: return "agotado"
            case .triste: return "triste"
            }
        }
    }
    
    // MARK: - UI
    struct UI {
        var accentColor: Color = .mint
        var recordButton = RecordButton()
        
        // Colores centralizados
        var backgroundColor: Color = Color(.systemGray6)     // gris muy claro para fondos
        var cardBackgroundColor: Color = .white              // blanco para cards
        
        struct EmotionItem {
            let imageName: String    // nombre del asset en el catálogo
            let color: Color
        }
        
        // Mapa de emociones -> imagen de asset + color
        var emotions: [AppConfig.Emotion: EmotionItem] = [
            // Existentes
//            .agotada:  EmotionItem(imageName: "agotada",   color: .gray),
//            .angry:    EmotionItem(imageName: "angry",     color: .red),
//            .charlatan:EmotionItem(imageName: "charlatan", color: .teal),
//            .creative: EmotionItem(imageName: "creative",  color: .purple),
//            .facinada: EmotionItem(imageName: "facinada",  color: .pink),
//            .inlove:   EmotionItem(imageName: "inlove",    color: .pink),
//            .suenio:   EmotionItem(imageName: "suenio",    color: .indigo),
            
            // Nuevas (colores sugeridos; ajusta si prefieres otros)
//            .adios:           EmotionItem(imageName: "adios",            color: .gray),
            .alerta:          EmotionItem(imageName: "alerta",           color: .orange),
            .angelical:       EmotionItem(imageName: "angelical",        color: .mint),
            .cansado:         EmotionItem(imageName: "cansado",          color: .gray),
            .carinioso:       EmotionItem(imageName: "carinioso",        color: .pink),
            .contento:        EmotionItem(imageName: "contento",         color: .yellow),
            .decepcionado:    EmotionItem(imageName: "decepcionado",     color: .blue),
            .demonio:         EmotionItem(imageName: "demonio",          color: .red),
//            .dinero:          EmotionItem(imageName: "dinero",           color: .green),
            .dormir:          EmotionItem(imageName: "dormir",           color: .indigo),
            .enamorado:       EmotionItem(imageName: "enamorado",        color: .pink),
            .enfadado:        EmotionItem(imageName: "enfadado",         color: .red),
            .enfermo:         EmotionItem(imageName: "enfermo",          color: .teal),
//            .gracioso:        EmotionItem(imageName: "gracioso",         color: .purple),
            .hambriento:      EmotionItem(imageName: "hambriento",       color: .orange),
            .herido:          EmotionItem(imageName: "herido",           color: .red),
//            .hola:            EmotionItem(imageName: "hola",             color: .blue),
            .llorando:        EmotionItem(imageName: "llorando",         color: .blue),
            .loca:            EmotionItem(imageName: "loca",             color: .pink),
            .muerto:          EmotionItem(imageName: "muerto",           color: .gray),
            .orgulloso:       EmotionItem(imageName: "orgulloso",        color: .yellow),
            .pasarPorAlto:    EmotionItem(imageName: "pasar-por-alto",   color: .gray),
            .pensamiento:     EmotionItem(imageName: "pensamiento",      color: .teal),
            .risa:            EmotionItem(imageName: "risa",             color: .orange),
            .solo:            EmotionItem(imageName: "solo",             color: .gray),
            .sorpresa:        EmotionItem(imageName: "sorpresa",         color: .orange),
            .suspiro:         EmotionItem(imageName: "suspiro",          color: .gray),
            .triste:          EmotionItem(imageName: "triste",           color: .blue)
        ]
        
        // Orden de chips (primero las originales, luego nuevas en un orden razonable)
        var emotionOrder: [AppConfig.Emotion] = [
            // Originales
//            .agotada, .angry, .charlatan, .creative, .facinada, .inlove, .suenio,
            // Nuevas (puedes ajustar el orden a gusto)
            .contento, .enamorado, .enfadado, .triste, .sorpresa, .alerta,
            .risa, .pensamiento, .carinioso, .angelical,
            .cansado, .dormir, // suenio ya está arriba; si no quieres duplicado, quita esta línea
            .hambriento, .enfermo, .herido, .orgulloso, .solo, .suspiro,
            .llorando, .loca, .muerto, .demonio, .pasarPorAlto, .decepcionado
        ]
        
        struct RecordButton {
            var size: CGFloat = 140
            
            // Colores
            var idleColor: Color = .blue
            var recordingColor: Color = .red
            
            // Animación de “respiración”
            var baseScale: CGFloat = 1.0
            var pulseScale: CGFloat = 1.18
            var pulseDuration: Double = 1.1
            
            // Halo
            var haloMinScale: CGFloat = 1.35
            var haloMaxScale: CGFloat = 1.7
            var haloMinOpacity: Double = 0.22
            var haloMaxOpacity: Double = 0.45
            var haloBlurRadius: CGFloat = 10
            
            // Botón: blur/sombra/opacidad cuando está grabando
            var recordingBlurRadius: CGFloat = 3.0
            var recordingShadowRadius: CGFloat = 16
            var recordingShadowColor: Color = Color.red.opacity(0.35)
            var idleShadowRadius: CGFloat = 8
            var idleShadowColor: Color = Color.black.opacity(0.15)
            var recordingOpacityLow: Double = 0.94
            
            // NUEVO: estilo “difuminado” cuando está idle
            var idleOpacity: Double = 0.9
            var idleBlurRadius: CGFloat = 1.0
            var idleMaterialOverlay: Bool = true
            
            // Separación con el timer u otros elementos debajo
            var bottomPadding: CGFloat = 16
        }
    }
    
    var audio = Audio()
    var ui = UI()
}

// MARK: - Helpers de emociones
extension AppConfig.Emotion {
    static func from(raw: String?) -> AppConfig.Emotion? {
        guard let raw else { return nil }
        return AppConfig.Emotion(rawValue: raw)
    }
}

// MARK: - Retención de audios
extension AppConfig {
    func cleanupOldEntries(context: NSManagedObjectContext) {
        let days = policy.retentionDays
        guard days > 0 else { return }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date().addingTimeInterval(-Double(days) * 86400)
        
        let fetch: NSFetchRequest<AudioEntry> = AudioEntry.fetchRequest()
        fetch.predicate = NSPredicate(format: "date < %@", cutoff as NSDate)
        
        do {
            let oldEntries = try context.fetch(fetch)
            guard !oldEntries.isEmpty else { return }
            
            for entry in oldEntries {
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
                context.delete(entry)
            }
            try context.save()
        } catch {
            print("Retention cleanup error: \(error)")
        }
    }
}
