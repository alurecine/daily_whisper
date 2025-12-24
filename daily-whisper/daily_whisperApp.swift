//
//  daily_whisperApp.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import SwiftUI
import CoreData

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
    
    var body: some Scene {
        WindowGroup {
            let content = Group {
                switch lockState {
                case .unlocked:
                    RootTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear { wasUnlockedOnce = true }
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
                    
                    // Asegurar que el límite diario arranque correcto (redundante, pero explícito)
                    AppConfig.shared.audio.maxEntriesPerDay = AppConfig.shared.policy.maxEntriesPerDay
                }
                .onChange(of: storedUserRoleRaw) { _, newValue in
                    // Cualquier cambio de rol persistido actualiza AppConfig en caliente
                    let role = AppConfig.UserRole(rawValue: newValue) ?? .normal
                    AppConfig.shared.subscription.role = role
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    
                    // Limpieza de retención al volver a primer plano
                    let context = persistenceController.container.viewContext
                    AppConfig.shared.cleanupOldEntries(context: context)
                    
                    guard requireOnForeground else { return }
                    guard wasUnlockedOnce else { return }
                    
                    if let last = lastUnlockDate, Date().timeIntervalSince(last) < 1.5 {
                        return
                    }
                    guard lockState == .unlocked else { return }
                    authenticateBiometricsFirst()
                }
        }
    }
    
    // MARK: - Autenticaciones (igual que tu última versión)
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
