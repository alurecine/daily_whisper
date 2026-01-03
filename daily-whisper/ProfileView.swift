//
//  ProfileView.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import PhotosUI
internal import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Estados UI (editables)
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = "" // Nuevo: teléfono solo en UserDefaults por ahora
    @State private var avatarImageData: Data?
    
    // Estados de control
    @State private var user: User?
    @State private var pickedItem: PhotosPickerItem?
    @State private var showPlans = false
    
    // Preferencia de seguridad
    @AppStorage("security.requireOnForeground") private var requireOnForeground: Bool = false
    
    // Rol persistido
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    
    // Flag para controlar el estado del onboarding desde Perfil (debug)
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Store de notificaciones
    @StateObject private var pushStore = NotificationsManager.store
    
    // Color de acento centralizado
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    var avatarImage: Image {
        if let data = avatarImageData,
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.crop.circle.fill")
    }
    
    private var currentPlanDescription: String {
        switch AppConfig.shared.subscription.role {
        case .normal:
            return "Normal — 1 audio/día, 30s por audio, historial 7 días"
        case .pro:
            return "PRO — 5 audios/día, 60s por audio, historial 30 días"
        case .unlimited:
            return "ILIMITADO — audios sin límite, 120s por audio, historial 90 días"
        }
    }
    
    var body: some View {
        ZStack {
            Form {
                // Header
                Section {
                    VStack(spacing: 12) {
                        PhotosPicker(
                            selection: $pickedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            AnyView(
                                avatarImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption2.weight(.bold))
                                            .padding(6)
                                            .background(.thinMaterial)
                                            .clipShape(Circle())
                                            .offset(x: 4, y: 4)
                                    }
                                    .contentShape(Rectangle())
                            )
                        }
                        .buttonStyle(.plain)
                        
                        VStack(spacing: 4) {
                            Text(name.isEmpty ? "Tu nombre" : name)
                                .font(.headline)
                            Text(email.isEmpty ? "tu@email.com" : email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .textSelection(.disabled)
                            // Nuevo: Teléfono debajo del email si existe
                            if !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textSelection(.disabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                
                // Datos personales
                Section(header: Text("Datos personales")) {
                    TextField("Nombre", text: $name)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    // Nuevo: Teléfono (UserDefaults)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: phone) { _, newValue in
                            // Guardado inmediato opcional para no perderlo
                            UserDefaults.standard.set(newValue, forKey: "profile.phone")
                        }
                }
                
                // Suscripción
                Section(header: Text("Suscripción")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Plan actual")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(currentPlanDescription)
                                .font(.headline)
                        }
                        Spacer()
                        switch AppConfig.shared.subscription.role {
                        case .normal:
                            Text("Normal")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        case .pro:
                            Text("PRO")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accent.opacity(0.15))
                                .foregroundColor(accent)
                                .clipShape(Capsule())
                        case .unlimited:
                            Text("ILIMITADO")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Button {
                        showPlans = true
                    } label: {
                        Label("Ver planes y precios", systemImage: "creditcard.fill")
                    }
                }
                
                // Suscripción (debug)
                Section(header: Text("Suscripción (debug)")) {
                    Picker("Rol actual", selection: Binding(
                        get: { AppConfig.shared.subscription.role },
                        set: { newRole in
                            AppConfig.shared.subscription.role = newRole
                            storedUserRoleRaw = newRole.rawValue
                        }
                    )) {
                        Text("Normal").tag(AppConfig.UserRole.normal)
                        Text("PRO").tag(AppConfig.UserRole.pro)
                        Text("ILIMITADO").tag(AppConfig.UserRole.unlimited)
                    }
                    .pickerStyle(.segmented)
                    Text("Usa este control solo para pruebas. Persistimos el rol en AppStorage para que el resto de la app reaccione.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Notificaciones
                Section(
                    header: Text("Notificaciones"),
                    footer: Text(footerText)
                ) {
                    Toggle("Notificaciones push", isOn: pushStore.desiredEnabledBinding)
                    Toggle("Sonidos", isOn: .init(
                        get: { UserDefaults.standard.bool(forKey: "profile.soundEnabled") },
                        set: { UserDefaults.standard.set($0, forKey: "profile.soundEnabled") }
                    ))
                    .disabled(!(pushStore.isAuthorized && pushStore.isRegisteredForRemoteNotifications))
                    .opacity(pushStore.isAuthorized && pushStore.isRegisteredForRemoteNotifications ? 1 : 0.5)
                    Toggle("Resumen diario", isOn: .init(
                        get: { UserDefaults.standard.bool(forKey: "profile.dailySummary") },
                        set: { UserDefaults.standard.set($0, forKey: "profile.dailySummary") }
                    ))
                    .disabled(!(pushStore.isAuthorized && pushStore.isRegisteredForRemoteNotifications))
                    .opacity(pushStore.isAuthorized && pushStore.isRegisteredForRemoteNotifications ? 1 : 0.5)
                }
                
                // Más
                Section(header: Text("Más")) {
                    Toggle("Requerir Face ID al volver a la app", isOn: $requireOnForeground)
                    
                    NavigationLink(destination:
                        Text("Preferencias de privacidad")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                    ) {
                        Label("Privacidad", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination:
                        Text("Centro de ayuda")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                    ) {
                        Label("Ayuda", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination:
                        Text("Términos y condiciones")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                    ) {
                        Label("Términos y condiciones", systemImage: "doc.text.fill")
                    }
                }
                
                // Onboarding (debug)
                Section(header: Text("Onboarding")) {
                    Toggle("Marcar onboarding como completado", isOn: $hasCompletedOnboarding)
                    Text(hasCompletedOnboarding ? "El onboarding está marcado como completado. Al iniciar, la app irá directo al flujo normal." :
                         "El onboarding NO está completado. Al iniciar, verás el onboarding.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: pickedItem) { _, newValue in
                Task { await loadPickedPhoto(newValue) }
            }
            .onAppear {
                if let role = AppConfig.UserRole(rawValue: storedUserRoleRaw) {
                    AppConfig.shared.subscription.role = role
                }
                loadUser()
            }
            .onDisappear {
                autoSaveIfNeeded()
            }
            .sheet(isPresented: $showPlans) {
                NavigationStack {
                    PlansView()
                }
                .presentationDetents([.large])
            }
        }
    }
    
    private var footerText: String {
        switch pushStore.authorizationStatus {
        case .denied:
            return "Las notificaciones están desactivadas en Ajustes. Toca el interruptor para abrir Ajustes y habilitarlas."
        case .notDetermined:
            return "Te pediremos permiso cuando actives el interruptor."
        case .authorized, .provisional, .ephemeral:
            return "Configura cómo y cuándo quieres recibir avisos."
        @unknown default:
            return "Configura cómo y cuándo quieres recibir avisos."
        }
    }
    
    // MARK: - Carga y guardado
    
    func loadUser() {
        do {
            let u = try UserRepository.fetchOrCreateUser(in: viewContext)
            self.user = u
            
            let defaults = UserDefaults.standard
            let storedName = defaults.string(forKey: "profile.name")
            let storedEmail = defaults.string(forKey: "profile.email")
            let storedAvatarData = defaults.data(forKey: "profile.avatarData")
            let storedPhone = defaults.string(forKey: "profile.phone") // Nuevo: teléfono solo en defaults
            
            var didMigrate = false
            if let storedName, !(storedName.isEmpty) {
                u.name = storedName
                didMigrate = true
            }
            if let storedEmail, !(storedEmail.isEmpty) {
                u.email = storedEmail
                didMigrate = true
            }
            if let storedAvatarData {
                u.profileImageData = storedAvatarData
                didMigrate = true
            }
            if didMigrate {
                u.updatedAt = Date()
                try? viewContext.save()
                
                defaults.removeObject(forKey: "profile.name")
                defaults.removeObject(forKey: "profile.email")
                defaults.removeObject(forKey: "profile.avatarData")
                // Nota: no removemos "profile.phone" porque aún no existe en Core Data
            }
            
            self.name = u.name ?? ""
            self.email = u.email ?? ""
            self.avatarImageData = u.profileImageData
            self.phone = storedPhone ?? self.phone // mantener lo que ya había si no hay defaults
            
        } catch {
            print("Error loading/creating User:", error)
        }
    }
    
    private func autoSaveIfNeeded() {
        guard let u = user else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let originalName = u.name ?? ""
        let originalEmail = u.email ?? ""
        let originalAvatar = u.profileImageData
        let originalPhone = UserDefaults.standard.string(forKey: "profile.phone") ?? ""
        
        let nameChanged = trimmedName != originalName
        let emailChanged = trimmedEmail != originalEmail
        let avatarChanged = avatarImageData != originalAvatar
        let phoneChanged = trimmedPhone != originalPhone
        
        guard nameChanged || emailChanged || avatarChanged || phoneChanged else { return }
        
        u.name = trimmedName.isEmpty ? nil : trimmedName
        u.email = trimmedEmail.isEmpty ? nil : trimmedEmail
        if avatarChanged {
            u.profileImageData = avatarImageData
        }
        // Guardar teléfono en UserDefaults (no hay campo en Core Data aún)
        if phoneChanged {
            UserDefaults.standard.set(trimmedPhone, forKey: "profile.phone")
        }
        u.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error auto-saving profile:", error)
        }
    }
    
    // MARK: - Imagen
    
    func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                self.avatarImageData = data
                if let u = self.user {
                    u.profileImageData = data
                    u.updatedAt = Date()
                    try? self.viewContext.save()
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
