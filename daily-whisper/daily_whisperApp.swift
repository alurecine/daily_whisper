//
//  daily_whisperApp.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import SwiftUI
internal import CoreData

@main
struct daily_whisperApp: App {
    let persistenceController = PersistenceController.shared
    
    enum LockState {
        case locked
        case unlocking
        case unlocked
    }
    
    @State private var lockState: LockState = .locked
    @State private var hasAttemptedInitialAuth = false
    @State private var wasUnlockedOnce = false
    @State private var lastUnlockDate: Date?
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Preferencias de apariencia (aplicadas globalmente aquí)
    @AppStorage("profile.useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("profile.forceDarkMode") private var forceDarkMode: Bool = false
    
    // Preferencia de seguridad
    @AppStorage("security.requireOnForeground") private var requireOnForeground: Bool = false
    
    // NUEVO: Rol persistido (fuente de verdad global)
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    
    private let authManager = BiometricAuthManager()
    
    // Theme manager global
    @State private var themeManager = ThemeManager() // init sin tocar self
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some Scene {
        WindowGroup {
            let content = Group {
                switch lockState {
                case .unlocked:
                    RootView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear { 
                            wasUnlockedOnce = true
                            migrateAudioEntryPaths(context: persistenceController.container.viewContext)
                        }
                case .locked, .unlocking:
                    LockView(
                        title: "Protegido con Face ID",
                        message: "Autentícate para continuar",
                        onUnlock: authenticateBiometricsFirst,
                        onUsePasscode: authenticateWithPasscode
                    )
                }
            }
            content
                .environment(\.themeManager, themeManager)
                .modifier(GlobalColorSchemeApplier(useSystemAppearance: useSystemAppearance, forceDarkMode: forceDarkMode))
                .onAppear {
                    // Autenticación inicial
                    guard !hasAttemptedInitialAuth else { return }
                    hasAttemptedInitialAuth = true
                    authenticateBiometricsFirst()
                    
                    // Sincronizar AppConfig con el rol persistido
                    if let role = AppConfig.UserRole(rawValue: storedUserRoleRaw) {
                        AppConfig.shared.subscription.role = role
                    } else {
                        AppConfig.shared.subscription.role = .normal
                        storedUserRoleRaw = AppConfig.UserRole.normal.rawValue
                    }
                    
                    // Asegurar que el límite diario arranque correcto
                    AppConfig.shared.audio.maxEntriesPerDay = AppConfig.shared.policy.maxEntriesPerDay
                    
                    // Actualizar tema inicial según preferencia del usuario
                    let targetScheme: ColorScheme? = useSystemAppearance ? colorScheme : (forceDarkMode ? .dark : .light)
                    themeManager.update(for: targetScheme)
                }
                .onChange(of: storedUserRoleRaw) { _, newValue in
                    let role = AppConfig.UserRole(rawValue: newValue) ?? .normal
                    AppConfig.shared.subscription.role = role
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    
                    // Limpieza de retención al volver a primer plano
                    let context = persistenceController.container.viewContext
                    AppConfig.shared.cleanupOldEntries(context: context)
                    
                    // Actualizar tema al volver
                    let targetScheme: ColorScheme? = useSystemAppearance ? colorScheme : (forceDarkMode ? .dark : .light)
                    themeManager.update(for: targetScheme)
                    
                    guard requireOnForeground else { return }
                    guard wasUnlockedOnce else { return }
                    
                    if let last = lastUnlockDate, Date().timeIntervalSince(last) < 1.5 {
                        return
                    }
                    guard lockState == .unlocked else { return }
                    authenticateBiometricsFirst()
                }
                .onChange(of: useSystemAppearance) { _, _ in
                    let targetScheme: ColorScheme? = useSystemAppearance ? colorScheme : (forceDarkMode ? .dark : .light)
                    themeManager.update(for: targetScheme)
                }
                .onChange(of: forceDarkMode) { _, _ in
                    let targetScheme: ColorScheme? = useSystemAppearance ? colorScheme : (forceDarkMode ? .dark : .light)
                    themeManager.update(for: targetScheme)
                }
                .onChange(of: colorScheme) { _, newScheme in
                    let targetScheme: ColorScheme? = useSystemAppearance ? newScheme : (forceDarkMode ? .dark : .light)
                    themeManager.update(for: targetScheme)
                }
        }
    }
    
    // MARK: - Migración de rutas de audio a nombre de archivo
    private func migrateAudioEntryPaths(context: NSManagedObjectContext) {
        let request: NSFetchRequest<AudioEntry> = AudioEntry.fetchRequest()
        do {
            let entries = try context.fetch(request)
            var didChange = false
            for entry in entries {
                guard let stored = entry.fileURL, !stored.isEmpty else { continue }
                
                let lower = stored.lowercased()
                if lower.hasPrefix("http://") || lower.hasPrefix("https://") { continue }
                
                let fileName: String
                if stored.hasPrefix("file://"), let url = URL(string: stored) {
                    fileName = url.lastPathComponent
                } else {
                    fileName = URL(fileURLWithPath: stored).lastPathComponent
                }
                
                if stored == fileName { continue }
                
                entry.fileURL = fileName
                didChange = true
            }
            if didChange {
                try context.save()
            }
        } catch {
            print("Migración de rutas falló:", error)
        }
    }
    
    // MARK: - Autenticaciones
    private func authenticateBiometricsFirst() {
        guard lockState != .unlocking else { return }
        lockState = .unlocking
        
        Task { @MainActor in
            let result = await authManager.authenticateBiometricsFirst(reason: "Acceder a tus audios")
            switch result {
            case .success, .notAvailable:
                withAnimation {
                    lockState = .unlocked
                    lastUnlockDate = Date()
                }
            case .failure:
                withAnimation { lockState = .locked }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        guard lockState != .unlocking else { return }
        lockState = .unlocking
        
        Task { @MainActor in
            let result = await authManager.authenticateWithPasscode(reason: "Acceder a tus audios")
            switch result {
            case .success, .notAvailable:
                withAnimation {
                    lockState = .unlocked
                    lastUnlockDate = Date()
                }
            case .failure:
                withAnimation { lockState = .locked }
            }
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "daily_whisper")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
    }
}

