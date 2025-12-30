import SwiftUI
import AVFoundation
import UserNotifications
import UIKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentIndex: Int = 0
    
    // Estado de permisos
    @State private var micStatus: AVAudioSession.RecordPermission = .undetermined
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    
    @Environment(\.themeManager) private var theme

    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Saltar") {
                    finish()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            
            TabView(selection: $currentIndex) {
                OnboardingIntroPage()
                    .tag(0)
                    .padding(.horizontal, 24)
                
                OnboardingPlansPage(accent: accent)
                    .tag(1)
                    .padding(.horizontal, 24)
                
                OnboardingPermissionsPage()
                .tag(2)
                .padding(.horizontal, 24)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            HStack(spacing: 12) {
                Button(action: previous) {
                    Text("Atrás")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .disabled(currentIndex == 0)
                
                Button(action: nextOrFinish) {
                    Text(currentIndex == 2 ? "Empezar" : "Continuar")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(AppConfig.shared.ui.backgroundColor.ignoresSafeArea())
        .onAppear {
            refreshPermissionStates()
        }
    }
    
    private func previous() {
        guard currentIndex > 0 else { return }
        withAnimation { currentIndex -= 1 }
    }
    private func nextOrFinish() {
        if currentIndex < 2 {
            withAnimation { currentIndex += 1 }
        } else {
            finish()
        }
    }
    private func finish() {
        // Pedir permiso y registrar APNs a través del manager
        NotificationsManager.shared.requestAuthorizationAndRegisterForRemoteNotifications()
        // Marcar onboarding como completado para iniciar la app
        hasCompletedOnboarding = true
    }
    
    // MARK: - Permisos
    private func refreshPermissionStates() {
        micStatus = AVAudioSession.sharedInstance().recordPermission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notifStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestMic() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            DispatchQueue.main.async {
                self.micStatus = AVAudioSession.sharedInstance().recordPermission
            }
        }
    }
    
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async {
                self.refreshPermissionStates()
            }
        }
    }
}

private struct OnboardingIntroPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(AppConfig.shared.ui.accentColor.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: "mic.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(AppConfig.shared.ui.accentColor)
            }
            Text("Hablar también es cuidarte.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Graba pensamientos en audios breves, dales una emoción y empieza a entenderte mejor, día a día.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingPlansPage: View {
    @Environment(\.themeManager) private var theme
    let accent: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(accent)
                .padding(.bottom, 8)
            
            Text("Elegí cómo acompañarte")
                .font(.title2.bold())
                .foregroundColor(theme.colors.cardTitle)
            
            VStack(spacing: 12) {
                PlanRow(title: "Normal", subtitle: "Un espacio diario para escucharte • 1 audio por día • Últimos 7 días • Hasta 30 segundos", icon: "person.crop.circle")
                PlanRow(title: "PRO", subtitle: "Más tiempo, más continuidad • Hasta 5 audios por día • 30 días de historial • Hasta 60 segundos", icon: "crown.fill")
                PlanRow(title: "ILIMITADO", subtitle: "Todo lo que necesites decir • Audios sin límite • 90 días de historial • Hasta 2 minutos por audio", icon: "infinity")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppConfig.shared.ui.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            
            Spacer(minLength: 0)
        }
    }
    
    private struct PlanRow: View {
        @Environment(\.themeManager) private var theme
        let title: String
        let subtitle: String
        let icon: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppConfig.shared.ui.accentColor)
                    .frame(width: 34, height: 34)
                    .background(AppConfig.shared.ui.accentColor.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(theme.colors.cardTitle)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.cardSubtitle)
                }
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.colors.cardBackground)
            )
        }
    }
}

private struct OnboardingPermissionsPage: View {
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .padding(.bottom, 8)
            
            Text("Permisos necesarios para poder escucharte")
                .font(.title2.bold())
            
            VStack(spacing: 12) {
                PermissionRow(
                    title: "Micrófono",
                    subtitle: "Para que puedas expresar lo que sentís."
                )
                Divider()
                PermissionRow(
                    title: "Notificaciones",
                    subtitle: "Para acompañarte con recordatorios suaves."
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppConfig.shared.ui.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            
            Text("Vos tenés el control. Podés cambiar estos permisos cuando quieras desde Ajustes.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer(minLength: 0)
        }
    }
    
    private struct PermissionRow: View {
        let title: String
        let subtitle: String
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.headline)
                        Text(subtitle).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppConfig.shared.ui.cardBackgroundColor)
                )
            }
        }
    }
}

#Preview {
    OnboardingView()
}
