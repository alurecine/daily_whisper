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
    
    // Filtro de emoción (nil = Todos)
    @State private var selectedFilter: AppConfig.Emotion? = nil
    
    // Picker de emoción al finalizar grabación
    @State private var showEmotionPicker = false
    @State private var pendingURL: URL?
    @State private var pendingDuration: Double = 0
    @State private var selectedEmotion: AppConfig.Emotion?
    
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
                            // Capturamos y pedimos emoción
                            pendingURL = url
                            pendingDuration = duration
                            selectedEmotion = nil
                            withAnimation(.easeInOut) {
                                showEmotionPicker = true
                            }
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
                        HStack {
                            if entries.isEmpty {
                                Text("Tus audios")
                                    .font(.title.bold())
                                    .opacity(0.4)
                            } else {
                                Text("Tus audios")
                                    .font(.title.bold())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Filtro visual por emoción (chips con icono + nombre)
                        EmotionFilterChips(selected: $selectedFilter)
                            .padding(.horizontal, 16)
                        
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
                            .background(Color(.systemGroupedBackground))
                        } else {
                            // Secciones por día
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
            
            // Modal de selección de emoción con fondo difuminado
            if showEmotionPicker {
                EmotionPickerOverlay(
                    isPresented: $showEmotionPicker,
                    onSelect: { emotion in
                        self.selectedEmotion = emotion
                        if let url = pendingURL {
                            saveEntry(url: url, duration: pendingDuration, emotion: emotion)
                            pendingURL = nil
                            pendingDuration = 0
                        }
                    }
                )
                .transition(.opacity .combined(with: .scale))
                .zIndex(10)
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

// MARK: - Selector visual por emoción (chips)
private struct EmotionFilterChips: View {
    @Binding var selected: AppConfig.Emotion?
    
    private var orderedEmotions: [AppConfig.Emotion] {
        AppConfig.shared.ui.emotionOrder
    }
    private var config: [AppConfig.Emotion: AppConfig.UI.EmotionItem] {
        AppConfig.shared.ui.emotions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filtrar por emoción")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Chip "Todos"
                    Chip(
                        isSelected: selected == nil,
                        label: {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text("Todos")
                            }
                        },
                        color: .secondary
                    ) {
                        withAnimation(.easeInOut) {
                            selected = nil
                        }
                    }
                    
                    // Chips por emoción
                    ForEach(orderedEmotions, id: \.rawValue) { emotion in
                        if let item = config[emotion] {
                            Chip(
                                isSelected: selected == emotion,
                                label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: item.systemImage)
                                            .foregroundStyle(item.color)
                                        Text(emotion.title)
                                    }
                                },
                                color: item.color
                            ) {
                                withAnimation(.easeInOut) {
                                    selected = emotion
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Chip genérico
private struct Chip<Label: View>: View {
    let isSelected: Bool
    @ViewBuilder let label: Label
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            label
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? color.opacity(0.18) : Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? color : Color.black.opacity(0.08), lineWidth: isSelected ? 1.4 : 0.5)
                )
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}

// MARK: - Header de día (separador)
private struct DayHeader: View {
    let date: Date
    
    var body: some View {
        Text(formatted(date))
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }
    
    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full // ej: "lunes, 23 de diciembre de 2025"
        return f.string(from: date)
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
    
    private var emotionInfo: (symbol: String, color: Color)? {
        guard let emotion = AppConfig.Emotion.from(raw: entry.emotion) else { return nil }
        if let item = AppConfig.shared.ui.emotions[emotion] {
            return (item.systemImage, item.color)
        }
        return nil
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
                HStack(spacing: 6) {
                    if let info = emotionInfo {
                        Image(systemName: info.symbol)
                            .foregroundStyle(info.color)
                    }
                    Text(formattedDate(entry.date ?? Date()))
                        .font(.headline)
                }
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
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Overlay de selección de emoción
private struct EmotionPickerOverlay: View {
    @Binding var isPresented: Bool
    let onSelect: (AppConfig.Emotion) -> Void
    
    private var items: [(emotion: AppConfig.Emotion, item: AppConfig.UI.EmotionItem)] {
        let order = AppConfig.shared.ui.emotionOrder
        let dict = AppConfig.shared.ui.emotions
        return order.compactMap { e in
            guard let item = dict[e] else { return nil }
            return (e, item)
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo difuminado
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isPresented = false
                    }
                }
            
            // Card central
            VStack(spacing: 16) {
                Text("¿Cómo te sientes?")
                    .font(.headline)
                    .padding(.top, 12)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(items, id: \.emotion) { pair in
                        Button {
                            withAnimation(.easeInOut) {
                                onSelect(pair.emotion)
                                isPresented = false
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: pair.item.systemImage)
                                    .font(.system(size: 28))
                                    .foregroundStyle(pair.item.color)
                                Text(pair.emotion.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                
                Button {
                    withAnimation(.easeInOut) {
                        isPresented = false
                    }
                } label: {
                    Text("Omitir")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 360)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }
}

