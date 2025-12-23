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
    @AppStorage("profile.accentColorTag") private var accentColorTag: Int = 0 // 0=Mint,1=Blue,2=Orange,3=Purple
    
    // NUEVO: Preferencia de seguridad
    @AppStorage("security.requireOnForeground") private var requireOnForeground: Bool = false
    
    // Estado UI
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showSavedToast = false
    
    // Foto de perfil
    @State private var pickedItem: PhotosPickerItem?
    @State private var avatarImageData: Data?
    @AppStorage("profile.avatarData") private var storedAvatarData: Data?
    
    // Apariencia (ya no aplicada localmente; se aplica globalmente en RootTabView)
    @AppStorage("profile.useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("profile.forceDarkMode") private var forceDarkMode: Bool = false
    
    var avatarImage: Image {
        if let data = avatarImageData ?? storedAvatarData,
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.crop.circle.fill")
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
                
                // Apariencia (movida antes que Notificaciones)
                Section(header: Text("Apariencia")) {
                    Toggle("Usar apariencia del sistema", isOn: $useSystemAppearance)
                    Toggle("Forzar modo oscuro", isOn: $forceDarkMode)
                        .disabled(useSystemAppearance)
                        .opacity(useSystemAppearance ? 0.5 : 1)
                    
                    Picker("Color de acento", selection: $accentColorTag) {
                        Text("Mint").tag(0)
                        Text("Blue").tag(1)
                        Text("Orange").tag(2)
                        Text("Purple").tag(3)
                    }
                }
                
                // Notificaciones (queda igual, solo cambia de lugar)
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
                
                // Privacidad y ayuda
                Section(header: Text("Más")) {
                    // NUEVO: Seguridad con Face ID al volver
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

