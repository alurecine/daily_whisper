import Foundation
import SwiftUI
import UserNotifications
import UIKit
import Combine

// Store observable para reflejar y gestionar el estado de notificaciones
@MainActor
final class PushPermissionStore: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isRegisteredForRemoteNotifications: Bool = UIApplication.shared.isRegisteredForRemoteNotifications
    
    // Conveniencia para la UI
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        @unknown default: return false
        }
    }
    
    // Si quieres que el Toggle represente el PERMISO del sistema:
    // - get = isAuthorized
    // - set(true) => pedir permiso/registrar
    // - set(false) => abrir Ajustes (el sistema no permite revocar desde la app)
    var desiredEnabledBinding: Binding<Bool> {
        Binding(
            get: { self.isAuthorized },
            set: { newValue in
                Task { await self.handleToggleChangeReflectingSystemPermission(newValue) }
            }
        )
    }
    
    init() {
        Task { await refresh() }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }
    
    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // Toggle que refleja el permiso del sistema
    private func handleToggleChangeReflectingSystemPermission(_ enable: Bool) async {
        await refresh()
        if enable {
            switch authorizationStatus {
            case .notDetermined:
                let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await refresh()
                if granted == true || isAuthorized {
                    await registerForRemoteNotifications()
                }
            case .authorized, .provisional, .ephemeral:
                await registerForRemoteNotifications()
            case .denied:
                openSettings()
            @unknown default:
                break
            }
        } else {
            // Para deshabilitar notificaciones a nivel sistema, debemos llevar al usuario a Ajustes.
            openSettings()
            // Opcionalmente también te “desregistras” para no recibir mientras tanto.
            await unregisterForRemoteNotifications()
        }
        await refresh()
    }
    
    // Si prefieres que el Toggle represente "permiso + registro", vuelve a la versión anterior.
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    private func unregisterForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
}

final class NotificationsManager {
    static let shared = NotificationsManager()
    private init() {}
    
    // Store compartido para la UI
    static let store = PushPermissionStore()

    // Solicita autorización y, si se concede, registra con APNs
    func requestAuthorizationAndRegisterForRemoteNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification auth error:", error)
            }
            guard granted else {
                print("🚫 User denied notifications")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // En primer plano, si el usuario habilitó notificaciones en Ajustes, registrar APNs
    func ensureRegisteredIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined, .denied:
                break
            @unknown default:
                break
            }
        }
    }
}

