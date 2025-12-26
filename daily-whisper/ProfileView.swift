//
//  ProfileView.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    // Persistencia simple
    @AppStorage("profile.name") private var storedName: String = "Tu nombre"
    @AppStorage("profile.email") private var storedEmail: String = "tu@email.com"
    @AppStorage("profile.pushEnabled") private var pushEnabled: Bool = true
    @AppStorage("profile.soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("profile.dailySummary") private var dailySummary: Bool = false
    
    // Preferencia de seguridad
    @AppStorage("security.requireOnForeground") private var requireOnForeground: Bool = false
    
    // Estado UI
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showSavedToast = false
    @State private var showPlans = false
    
    // Foto de perfil
    @State private var pickedItem: PhotosPickerItem?
    @State private var avatarImageData: Data?
    @AppStorage("profile.avatarData") private var storedAvatarData: Data?
    
    // Apariencia (aplicada globalmente en RootTabView)
    @AppStorage("profile.useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("profile.forceDarkMode") private var forceDarkMode: Bool = false
    
    // TEST: rol de usuario (persistido para pruebas)
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    
    // Color de acento centralizado
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    var avatarImage: Image {
        if let data = avatarImageData ?? storedAvatarData,
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.crop.circle.fill")
    }
    
    // Descripción legible del plan actual
    private var currentPlanDescription: String {
        switch AppConfig.shared.subscription.role {
        case .normal:
            return "Normal — 1 audio/día, historial 7 días"
        case .pro:
            return "PRO — 5 audios/día, historial 30 días"
        }
    }
    
    var body: some View {
        ZStack {
            Form {
                // Header con foto + nombre + email
                Section {
                    VStack(spacing: 12) {
                        PhotosPicker(
                            selection: $pickedItem,
                            matching: .images,
                            photoLibrary: .shared(),
                            label: {
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
                            }
                        )
                        .buttonStyle(.plain)
                        
                        VStack(spacing: 4) {
                            Text(name.isEmpty ? storedName : name)
                                .font(.headline)
                            Text(email.isEmpty ? storedEmail : email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .textSelection(.disabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                
                // Datos personales editables
                Section(header: Text("Datos personales")) {
                    TextField("Nombre", text: $name)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                // Apariencia (sin color de acento configurable)
                Section(header: Text("Apariencia")) {
                    Toggle("Usar apariencia del sistema", isOn: $useSystemAppearance)
                    Toggle("Forzar modo oscuro", isOn: $forceDarkMode)
                        .disabled(useSystemAppearance)
                        .opacity(useSystemAppearance ? 0.5 : 1)
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
                        if AppConfig.shared.subscription.role == .normal {
                            Text("Normal")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        } else {
                            Text("PRO")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accent.opacity(0.15))
                                .foregroundColor(accent)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Button {
                        showPlans = true
                    } label: {
                        Label("Ver planes y precios", systemImage: "creditcard.fill")
                    }
                }
                
                // Notificaciones
                Section(
                    header: Text("Notificaciones"),
                    footer: Text("Configura cómo y cuándo quieres recibir avisos.")
                ) {
                    Toggle("Notificaciones push", isOn: $pushEnabled)
                    Toggle("Sonidos", isOn: $soundEnabled)
                        .disabled(!pushEnabled)
                        .opacity(pushEnabled ? 1 : 0.5)
                    Toggle("Resumen diario", isOn: $dailySummary)
                }
                
                // Más
                Section(header: Text("Más")) {
                    // Seguridad con Face ID al volver
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
                
                // SOLO TEST: Selector de rol (quitar antes de release)
                Section(header: Text("(Solo test) Rol de usuario")) {
                    Picker("Rol", selection: $storedUserRoleRaw) {
                        Text("Normal").tag(AppConfig.UserRole.normal.rawValue)
                        Text("PRO").tag(AppConfig.UserRole.pro.rawValue)
                    }
                    .onChange(of: storedUserRoleRaw) { _, newValue in
                        if let role = AppConfig.UserRole(rawValue: newValue) {
                            AppConfig.shared.subscription.role = role
                        }
                    }
                    Text("Este selector es solo para pruebas internas. Elimínalo antes de publicar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Guardar y cerrar sesión
                Section {
                    Button(action: saveProfile) {
                        Label("Guardar cambios", systemImage: "checkmark.circle.fill")
                    }
                    
                    Button(role: .destructive, action: {
                        // Lógica de logout en el futuro
                    }) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .onChange(of: pickedItem) { _, newValue in
                Task { await loadPickedPhoto(newValue) }
            }
            .onAppear {
                // precargar datos en campos editables
                name = storedName
                email = storedEmail
                if avatarImageData == nil {
                    avatarImageData = storedAvatarData
                }
                // Sincronizar AppConfig con el valor persistido de test
                if let role = AppConfig.UserRole(rawValue: storedUserRoleRaw) {
                    AppConfig.shared.subscription.role = role
                }
            }
            .sheet(isPresented: $showPlans) {
                NavigationStack {
                    PlansView()
                }
                .presentationDetents([.large])
            }
            
            if showSavedToast {
                VStack {
                    Spacer()
                    Text("Cambios guardados")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: showSavedToast)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func saveProfile() {
        storedName = name.isEmpty ? "Tu nombre" : name
        storedEmail = email.isEmpty ? "tu@email.com" : email
        storedAvatarData = avatarImageData
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showSavedToast = false }
        }
    }
    
    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                self.avatarImageData = data
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
