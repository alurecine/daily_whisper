//
//  HomeView.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import SwiftUI
internal import CoreData
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
    
    // Filtro de emoción (nil = Todos)
    @State private var selectedFilter: AppConfig.Emotion? = nil
    
    // Datos pendientes post-grabación
    @State private var pendingFileURL: URL?
    @State private var pendingDuration: Double = 0
    
    // Popup modal en la misma pantalla para elegir emoción
    @State private var showEmotionPopup = false
    @State private var selectedEmotionForSave: AppConfig.Emotion? = nil
    
    // Overlay de grabación full screen con RecordButtonView
    @State private var showQuickRecordOverlay = false
    
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
    
    // MARK: - Filtro por emoción
    private var entriesFiltered: [AudioEntry] {
        guard let filter = selectedFilter else { return Array(entries) }
        return entries.filter { entry in
            AppConfig.Emotion.from(raw: entry.emotion) == filter
        }
    }
    
    // MARK: - Agrupación por día
    private var groupedByDay: [(day: Date, items: [AudioEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: entriesFiltered) { entry in
            calendar.startOfDay(for: entry.date ?? Date())
        }
        // Orden descendente por día
        let sortedDays = groups.keys.sorted(by: >)
        return sortedDays.map { day in
            // Asegurar orden por fecha dentro de cada día (desc)
            let items = (groups[day] ?? []).sorted { (a, b) in
                (a.date ?? .distantPast) > (b.date ?? .distantPast)
            }
            return (day, items)
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo base (centralizado)
            AppConfig.shared.ui.backgroundColor.ignoresSafeArea()
            
            // Contenido principal: encabezado fijo + filtros fijos + lista scrollable
            VStack(alignment: .leading, spacing: 12) {
                // Título fijo
                HStack {
                    Text("Tus audios")
                        .font(.title.bold())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Filtro fijo por emoción
                EmotionFilterChips(selected: $selectedFilter)
                    .padding(.horizontal, 16)
                
                // Solo la lista hace scroll
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if entriesFiltered.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No hay audios para este filtro")
                                    .font(.headline)
                                Text("Graba un audio o cambia el filtro de emoción.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(AppConfig.shared.ui.backgroundColor)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                                ForEach(groupedByDay, id: \.day) { group in
                                    VStack(alignment: .leading, spacing: 10) {
                                        DayHeader(date: group.day)
                                            .padding(.horizontal, 16)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(group.items) { entry in
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
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .background(AppConfig.shared.ui.backgroundColor)
            
            // Banner permanente para usuarios normales (queda sobre el contenido)
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
                    .padding(.bottom, 72) // dejar espacio para el FAB
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: AppConfig.shared.subscription.role)
            }
            
            // FAB flotante "GRABAR +"
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        // Si alcanzó el límite, abrir sheet de planes en vez de grabar
                        if hasReachedDailyLimit {
                            showPlans = true
                        } else {
                            // Mostrar overlay de grabación
                            showQuickRecordOverlay = true
                            // Resetear contador si no está grabando
                            recorder.reset()
                            pendingFileURL = nil
                            pendingDuration = 0
                            // No preseleccionar emoción
                            selectedEmotionForSave = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                            Text("GRABAR +")
                                .font(.headline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("fabRecord")
                }
            }
            
            // Overlay full-screen para grabar en la misma pantalla
            if showQuickRecordOverlay {
                QuickRecordOverlay(
                    recorder: recorder,
                    maxDuration: AppConfig.shared.audio.maxRecordingDuration
                ) { url, duration in
                    // Al terminar, guardamos la URL/duración y abrimos el popup de emoción
                    pendingFileURL = url
                    pendingDuration = duration
                    // No forzar emoción por defecto
                    withAnimation(.easeInOut) { showEmotionPopup = true }
                }
                .transition(.opacity)
                .zIndex(20)
            }
            
            // Popup modal de emociones (no sheet): mismo screen
            if showEmotionPopup {
                EmotionInlinePopup(
                    selected: $selectedEmotionForSave,
                    onCancel: {
                        // Si cancela, borrar archivo temporal
                        if let url = pendingFileURL {
                            try? FileManager.default.removeItem(at: url)
                        }
                        // Detener cualquier grabación residual y cerrar overlay
                        if recorder.isRecording {
                            recorder.stopRecording()
                        }
                        pendingFileURL = nil
                        pendingDuration = 0
                        withAnimation(.easeInOut) { showEmotionPopup = false }
                        withAnimation(.easeInOut) { showQuickRecordOverlay = false }
                    },
                    onSelect: { emotion in
                        // Guardar al seleccionar y cerrar
                        if let url = pendingFileURL {
                            saveEntry(url: url, duration: pendingDuration, emotion: emotion)
                        }
                        // Detener cualquier grabación residual y cerrar overlay
                        if recorder.isRecording {
                            recorder.stopRecording()
                        }
                        pendingFileURL = nil
                        pendingDuration = 0
                        withAnimation(.easeInOut) { showEmotionPopup = false }
                        withAnimation(.easeInOut) { showQuickRecordOverlay = false }
                    }
                )
                .transition(.opacity)
                .zIndex(30)
            }
            
            // Toast Overlay para errores de reproducción (legacy local)
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
                .zIndex(40)
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
    
    private func saveEntry(url: URL, duration: Double, emotion: AppConfig.Emotion) {
        // Evitar superar el límite diario
        if hasReachedDailyLimit {
            return
        }
        
        let entry = AudioEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Date()
        entry.fileURL = url.path // guardamos ruta de archivo directa (sin esquema) para consistencia con normalizeURL
        entry.duration = duration
        entry.emotion = emotion.rawValue
        
        do {
            try viewContext.save()
            // Toast superior global
            ToastCenter.shared.success("Audio guardado", message: "Tu grabación se añadió a la lista")
        } catch {
            // Si falla el guardado, intentamos limpiar el archivo recién creado
            try? FileManager.default.removeItem(at: url)
            print("Core Data save error: \(error)")
            ToastCenter.shared.error("No se pudo guardar", message: "Intenta nuevamente")
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
            ToastCenter.shared.info("Audio eliminado")
        } catch {
            print("Core Data delete error: \(error)")
            ToastCenter.shared.error("No se pudo eliminar", message: "Intenta nuevamente")
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

// MARK: - QuickRecordOverlay: pantalla full-screen mínima con RecordButtonView

private struct QuickRecordOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var recorder: AudioRecorderManager
    let maxDuration: TimeInterval
    let onFinish: (URL, Double) -> Void
    
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    if !recorder.isRecording {
                        dismiss()
                    }
                }
            
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        if recorder.isRecording {
                            recorder.stopRecording()
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                Text(timeString(recorder.isRecording ? recorder.currentTime : 0) + " / " + timeString(maxDuration))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                RecordButtonView(recorder: recorder) { url, duration in
                    onFinish(url, duration)
                    dismiss()
                }
                
                Spacer()
            }
        }
    }
    
    private func timeString(_ t: TimeInterval) -> String {
        let seconds = Int(t.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%01d:%02d", m, s)
    }
}

// MARK: - EmotionInlinePopup: popup modal en la misma pantalla

private struct EmotionInlinePopup: View {
    @Binding var selected: AppConfig.Emotion?
    let onCancel: () -> Void
    let onSelect: (AppConfig.Emotion) -> Void
    
    private var order: [AppConfig.Emotion] { AppConfig.shared.ui.emotionOrder }
    private var map: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    
    // Columnas adaptativas para iPhone/iPad
    private var columns: [GridItem] {
        // Mínimo 140 para que quepa imagen + texto; se adaptará a 2, 3 o más columnas
        [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 8)]
    }
    
    var body: some View {
        ZStack {
            // Fondo desenfocado
            Rectangle()
                .fill(Color.black.opacity(0.25))
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            VStack(spacing: 12) {
                Text("¿Cómo te sentías?")
                    .font(.headline)
                    .padding(.top, 12)
                
                // Cuadrícula adaptativa
                LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                    ForEach(order, id: \.self) { emotion in
                        let item = map[emotion]
                        EmotionChip(
                            isSelected: selected == emotion,
                            imageName: item?.imageName,
                            title: emotion.title,
                            tint: item?.color ?? .gray
                        ) {
                            selected = emotion
                            onSelect(emotion)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text("Cancelar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 480)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 10)
            .transition(.opacity)
            .padding(.horizontal, 16)
        }
    }
}

private struct EmotionChip: View {
    let isSelected: Bool
    let imageName: String?
    let title: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    private var background: some ShapeStyle {
        isSelected ? AnyShapeStyle(tint.opacity(0.18)) : AnyShapeStyle(Color(.secondarySystemBackground))
    }
    private var foreground: some ShapeStyle {
        isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(.primary)
    }
    private var border: Color {
        isSelected ? tint : Color.black.opacity(0.08)
    }
}
