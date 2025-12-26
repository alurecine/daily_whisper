//
//  HomeView.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import AVFAudio

struct HomeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var recorder = AudioRecorderManager()
    @StateObject private var player = AudioPlayerManager()
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AudioEntry.date, ascending: false)
        ],
        animation: .default
    )
    private var entries: FetchedResults<AudioEntry>
    
    @State private var showToast = false
    @State private var showPlans = false
    
    // Color de acento centralizado
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    // MARK: - Restricción de audios por día (ahora configurable)
    private var hasReachedDailyLimit: Bool {
        let maxPerDay = AppConfig.shared.audio.maxEntriesPerDay
        guard maxPerDay > 0 else { return false } // 0 o negativo = sin límite
        let todayCount = entries.filter { entry in
            guard let date = entry.date else { return false }
            return Calendar.current.isDateInToday(date)
        }.count
        return todayCount >= maxPerDay
    }
    
    var body: some View {
        ZStack {
            // Fondo claro unificado
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Encabezado + Botón de grabación (fijo)
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Hoy")
                            .font(.largeTitle.bold())
                        Spacer()
                        if hasReachedDailyLimit {
                            Label("Día completo", systemImage: "checkmark.seal.fill")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                                .accessibilityIdentifier("savedTodayBadge")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Botón de grabación flotante (sin recuadro/card)
                    VStack(spacing: 10) {
                        RecordButtonView(recorder: recorder) { url, duration in
                            saveEntry(url: url, duration: duration)
                        }
                        .disabled(player.isPlaying || hasReachedDailyLimit)
                        .opacity((player.isPlaying || hasReachedDailyLimit) ? 0.5 : 1.0)
                        .animation(.easeInOut, value: player.isPlaying)
                        .animation(.easeInOut, value: hasReachedDailyLimit)
                        
                        // Mensajes de estado
                        if recorder.isRecording {
                            Text("\(Int(recorder.currentTime)) / \(Int(AppConfig.shared.audio.maxRecordingDuration))s")
                                .font(.caption.monospacedDigit())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        } else if hasReachedDailyLimit {
                            Text(limitMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if player.isPlaying {
                            Text("Pausa la reproducción para grabar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Mantén presionado para grabar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Contenido scrollable: ScrollView + LazyVStack
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Título de la sección como parte del contenido
                        if !entries.isEmpty {
                            Text("Tus audios")
                                .font(.title.bold())
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                        
                        if entries.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Aún no tienes audios")
                                    .font(.headline)
                                Text("Graba tu primer audio manteniendo presionado el botón.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(.systemGroupedBackground))
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    CardRow(
                                        entry: entry,
                                        player: player,
                                        isDisabled: recorder.isRecording,
                                        onDelete: { delete(entry: entry) }
                                    )
                                    .padding(.horizontal, 16)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            delete(entry: entry)
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            
            // Toast Overlay para errores de reproducción
            if showToast, let message = player.playbackErrorMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityIdentifier("toastMessage")
                }
                .animation(.easeInOut, value: showToast)
            }
            
            // Banner permanente para usuarios normales
            if AppConfig.shared.subscription.role == .normal {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "star.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pásate a PRO")
                                .font(.headline)
                            Text("Graba más por día y conserva tus audios por más tiempo.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            showPlans = true
                        } label: {
                            Text("Suscribirme")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: AppConfig.shared.subscription.role)
            }
        }
        .onAppear {
            recorder.requestPermission()
            
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default)
            
            // Conectar referencias cruzadas para coordinación
            recorder.player = player
            player.recorder = recorder
        }
        .onReceive(player.$playbackErrorMessage) { msg in
            guard msg != nil else {
                showToast = false
                return
            }
            withAnimation {
                showToast = true
            }
            // Ocultar automáticamente a los 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showToast = false
                }
                // Limpiar el mensaje para futuros toasts
                player.playbackErrorMessage = nil
            }
        }
        .sheet(isPresented: $showPlans) {
            NavigationStack {
                PlansView()
            }
            .presentationDetents([.large])
        }
    }
    
    private var limitMessage: String {
        let max = AppConfig.shared.audio.maxEntriesPerDay
        if max <= 0 { return "" }
        if max == 1 { return "Ya registraste tu audio de hoy" }
        return "Alcanzaste el límite de \(max) audios por día"
    }
    
    // MARK: - Core Data helpers
    
    private func saveEntry(url: URL, duration: Double) {
        // Evitar superar el límite diario
        if hasReachedDailyLimit {
            return
        }
        
        let entry = AudioEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Date()
        entry.fileURL = url.path // guardamos ruta de archivo directa (sin esquema) para consistencia con normalizeURL
        entry.duration = duration
        
        do {
            try viewContext.save()
        } catch {
            // Si falla el guardado, intentamos limpiar el archivo recién creado
            try? FileManager.default.removeItem(at: url)
            print("Core Data save error: \(error)")
        }
    }
    
    private func delete(entry: AudioEntry) {
        // 1) Borrar archivo físico si existe
        if let storedPath = entry.fileURL, let url = normalizeURL(from: storedPath) {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print("Error deleting file at \(url): \(error)")
                }
            }
        }
        // 2) Borrar de Core Data
        viewContext.delete(entry)
        do {
            try viewContext.save()
        } catch {
            print("Core Data delete error: \(error)")
        }
    }
    
    // Reutilizamos misma lógica que el Player para mayor robustez
    private func normalizeURL(from storedPath: String) -> URL? {
        if storedPath.hasPrefix("file://") {
            if let url = URL(string: storedPath) {
                return url
            }
            let trimmed = storedPath.replacingOccurrences(of: "file://", with: "")
            return URL(fileURLWithPath: "/" + trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        } else {
            return URL(fileURLWithPath: storedPath)
        }
    }
}

// MARK: - Card Row personalizada
private struct CardRow: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    let isDisabled: Bool
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                player.toggle(entry: entry)
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(entry.date ?? Date()))
                    .font(.headline)
                Text("\(Int(entry.duration)) segundos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Botón de eliminar a la derecha
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .tint(.red)
            .accessibilityLabel("Eliminar audio")
            .confirmationDialog("¿Eliminar este audio?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    onDelete()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
