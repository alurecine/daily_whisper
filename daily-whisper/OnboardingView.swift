import SwiftUI
import AVFoundation
import UserNotifications
import UIKit
internal import CoreData

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentIndex: Int = 0
    
    // Estados del slide de perfil (ahora la última página)
    @State private var profileName: String = UserDefaults.standard.string(forKey: "profile.name") ?? ""
    @State private var profileEmail: String = UserDefaults.standard.string(forKey: "profile.email") ?? ""
    @State private var profilePhone: String = UserDefaults.standard.string(forKey: "profile.phone") ?? ""
    
    @State private var micStatus: AVAudioSession.RecordPermission = .undetermined
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    
    @Environment(\.themeManager) private var theme

    private var accent: Color { theme.colors.accent }
    
    // Validaciones básicas
    private var isValidName: Bool { !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isValidEmail: Bool {
        let email = profileEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    private var isValidPhone: Bool {
        let phone = profilePhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phone.isEmpty else { return false }
        let pattern = #"^\+?[0-9\s\-]{6,20}$"#
        return phone.range(of: pattern, options: .regularExpression) != nil
    }
    private var isProfileValid: Bool { isValidName && isValidEmail && isValidPhone }
    
    // Cantidad de páginas: 4 (0..3), perfil es la última
    private let lastIndex = 3
    
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
                OnboardingIntroPage(accent: accent)
                    .tag(0)
                    .padding(.horizontal, 24)
                
                OnboardingPlansPage(accent: accent)
                    .tag(1)
                    .padding(.horizontal, 24)
                
                OnboardingPermissionsPage()
                    .tag(2)
                    .padding(.horizontal, 24)
                
                OnboardingProfilePage(
                    name: $profileName,
                    email: $profileEmail,
                    phone: $profilePhone,
                    accent: accent,
                    isValidName: isValidName,
                    isValidEmail: isValidEmail,
                    isValidPhone: isValidPhone
                )
                .tag(3)
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
                    Text(currentIndex == lastIndex ? "Empezar" : "Continuar")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isContinueDisabled ? Color.gray.opacity(0.4) : accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isContinueDisabled)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .onAppear {
            refreshPermissionStates()
        }
    }
    
    // Deshabilitar “Continuar” en la última página si los datos no son válidos
    private var isContinueDisabled: Bool {
        if currentIndex == lastIndex { return !isProfileValid }
        return false
    }
    
    private func previous() {
        guard currentIndex > 0 else { return }
        withAnimation { currentIndex -= 1 }
    }
    private func nextOrFinish() {
        if currentIndex < lastIndex {
            withAnimation { currentIndex += 1 }
        } else {
            finish()
        }
    }
    private func finish() {
        // 1) Persistir localmente (UserDefaults)
        persistProfileToUserDefaults()
        
        // 2) Guardar en Core Data (name/email) para que la app inicie ya con estos valores
        do {
            let user = try UserRepository.fetchOrCreateUser(in: viewContext)
            try UserRepository.update(
                in: viewContext,
                user: user,
                name: profileName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: profileEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            // Nota: phone queda en UserDefaults hasta que exista en el modelo
        } catch {
            print("Onboarding save user error:", error)
        }
        
        // 3) Notificaciones y salida
        NotificationsManager.shared.requestAuthorizationAndRegisterForRemoteNotifications()
        hasCompletedOnboarding = true
    }
    
    private func persistProfileToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(profileName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile.name")
        defaults.set(profileEmail.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile.email")
        defaults.set(profilePhone.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile.phone")
    }
    
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
    let accent: Color
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: "mic.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(accent)
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
                    .fill(theme.colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.colors.separator, lineWidth: 0.5)
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
                    .foregroundStyle(theme.colors.accent)
                    .frame(width: 34, height: 34)
                    .background(theme.colors.accent.opacity(0.12))
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
    @Environment(\.themeManager) private var theme
    
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
                    .fill(theme.colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.colors.separator, lineWidth: 0.5)
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
        @Environment(\.themeManager) private var theme
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
                        .fill(theme.colors.cardBackground)
                )
            }
        }
    }
}

// ÚLTIMA PÁGINA: Perfil
private struct OnboardingProfilePage: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    let accent: Color
    let isValidName: Bool
    let isValidEmail: Bool
    let isValidPhone: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(accent)
                .padding(.bottom, 8)
            
            Text("Tu perfil")
                .font(.title2.bold())
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nombre").font(.caption).foregroundColor(.secondary)
                    TextField("Tu nombre", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isValidName ? Color.clear : Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email").font(.caption).foregroundColor(.secondary)
                    TextField("tu@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isValidEmail ? Color.clear : Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Teléfono").font(.caption).foregroundColor(.secondary)
                    TextField("+54 9 11 1234 5678", text: $phone)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isValidPhone ? Color.clear : Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                
                if !(isValidName && isValidEmail && isValidPhone) {
                    Text("Completá los tres campos con datos válidos para continuar.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView()
}
