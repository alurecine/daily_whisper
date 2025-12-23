//
//  DashboardView.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
import CoreData
import Charts

struct DashboardView: View {
    
    // Core Data
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AudioEntry.date, ascending: false)
        ],
        animation: .default
    )
    private var allEntries: FetchedResults<AudioEntry>
    
    // Player local para reproducir desde el dashboard
    @StateObject private var player = AudioPlayerManager()
    
    // Datos de ejemplo para "Novedades"
    private let news: [NewsItem] = [
        .init(title: "Nueva función de grabación", subtitle: "Ahora puedes grabar hasta 30s con mejor calidad.", imageSystemName: "mic.circle.fill", tint: .mint),
        .init(title: "Mejoras en el reproductor", subtitle: "Controles más claros y correcciones de errores.", imageSystemName: "play.circle.fill", tint: .blue),
        .init(title: "Sincronización en camino", subtitle: "Muy pronto podrás sincronizar tus audios.", imageSystemName: "icloud.and.arrow.up.fill", tint: .purple),
        .init(title: "Estadísticas semanales", subtitle: "Estamos preparando métricas útiles para ti.", imageSystemName: "chart.bar.xaxis", tint: .orange)
    ]
    
    // Recomendaciones (array editable)
    private let recommendations: [RecommendationItem] = [
        .init(
            title: "Consejo de respiración",
            subtitle: "Prueba grabar tras 1 minuto de respiración consciente.",
            imageSystemName: "wind",
            tint: .teal,
            longText: """
            La respiración consciente ayuda a centrarte y calmar la mente. Antes de grabar, dedica 60 segundos a inhalar y exhalar profundamente. Esto puede mejorar la claridad de tus ideas y la calidad de tu voz.
            
            Sugerencia:
            - Inhala por la nariz durante 4 segundos.
            - Mantén el aire 2 segundos.
            - Exhala por la boca durante 6 segundos.
            - Repite 8-10 veces.
            """
        ),
        .init(
            title: "Graba al amanecer",
            subtitle: "Muchos usuarios encuentran claridad por la mañana.",
            imageSystemName: "sunrise.fill",
            tint: .orange,
            longText: """
            Las primeras horas del día suelen traer una mente más despejada. Aprovecha esa frescura para grabar tus ideas, objetivos o reflexiones. Podrías notar mayor coherencia y enfoque en tus mensajes.
            
            Tip:
            - Ten listo el dispositivo y un espacio tranquilo.
            - Anota un tema breve para guiarte antes de grabar.
            """
        ),
        .init(
            title: "Usa auriculares",
            subtitle: "Mejora la calidad y reduce el ruido ambiente.",
            imageSystemName: "headphones",
            tint: .purple,
            longText: """
            Unos auriculares con micrófono integrado pueden reducir el ruido y mejorar la nitidez del audio. Si grabas en exteriores o en ambientes con eco, los auriculares hacen una gran diferencia.
            
            Recomendación:
            - Ajusta el volumen y prueba una grabación corta.
            - Evita roces del micrófono con la ropa.
            """
        )
    ]
    
    // Estado para sheet de recomendaciones (usamos item: en lugar de isPresented:)
    @State private var selectedRecommendation: RecommendationItem?
    
    // Últimos 7 días para "Tu semana"
    private var lastWeekEntries: [AudioEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-7*24*3600)
        return allEntries.filter { entry in
            guard let d = entry.date else { return false }
            return d >= sevenDaysAgo
        }
    }
    
    // Datos para el gráfico del último mes (30 días): conteo por día
    private var monthlyActivity: [DailyCount] {
        let days = (0..<30).map { offset -> Date in
            Calendar.current.startOfDay(for: Date().addingTimeInterval(-Double(offset) * 86400))
        }
        var counts: [Date: Int] = [:]
        for entry in allEntries {
            guard let d = entry.date else { continue }
            let day = Calendar.current.startOfDay(for: d)
            if let minDay = days.last, day >= minDay {
                counts[day, default: 0] += 1
            }
        }
        let allDays = days.sorted()
        return allDays.map { DailyCount(date: $0, count: counts[$0, default: 0]) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Sección: Novedades
                SectionHeader("Novedades")
                NewsCarousel(items: news)
                
                // Sección: Tu semana (últimos 7 días)
                SectionHeader("Tu semana")
                if lastWeekEntries.isEmpty {
                    PlaceholderCard(height: 120)
                        .overlay(
                            Text("Aún no hay audios esta semana")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(lastWeekEntries) { entry in
                                AudioSquareCard(entry: entry, player: player)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Sección: Recomendaciones (carousel con imagen + texto)
                SectionHeader("Recomendaciones")
                RecommendationsCarousel(items: recommendations) { item in
                    // Asignamos el item antes de presentar la sheet
                    selectedRecommendation = item
                }
                
                // Sección: Resumen (gráfico del último mes)
                SectionHeader("Resumen del último mes")
                ActivityChart(data: monthlyActivity)
                    .frame(height: 220)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        // Sheet basada en item: garantiza contenido desde el primer render
        .sheet(item: $selectedRecommendation) { item in
            RecommendationDetailSheet(item: item)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Componentes comunes

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    
    var body: some View {
        Text(title)
            .font(.title2.bold())
            .padding(.horizontal, 16)
    }
}

private struct PlaceholderCard: View {
    var height: CGFloat = 140
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
    }
}

// MARK: - Novedades

private struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageSystemName: String
    let tint: Color
}

private struct NewsCarousel: View {
    let items: [NewsItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(items) { item in
                    NewsCard(item: item)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: item.imageSystemName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(item.tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Recomendaciones

private struct RecommendationItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageSystemName: String
    let tint: Color
    let longText: String
}

private struct RecommendationsCarousel: View {
    let items: [RecommendationItem]
    let onTap: (RecommendationItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(items) { item in
                    RecommendationCard(item: item)
                        .onTapGesture {
                            onTap(item)
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct RecommendationCard: View {
    let item: RecommendationItem
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.tint.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: item.imageSystemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(item.tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct RecommendationDetailSheet: View {
    let item: RecommendationItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.tint.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: item.imageSystemName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(item.tint)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            
            ScrollView {
                Text(item.longText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Card de audio cuadrada

private struct AudioSquareCard: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    
    private var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate(entry.date ?? Date()))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(Int(entry.duration)) s")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                player.toggle(entry: entry)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    Text(isPlaying ? "Detener" : "Reproducir")
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isPlaying ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                .foregroundColor(isPlaying ? .red : .blue)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 140, height: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Gráfico de actividad (último mes)

private struct DailyCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct ActivityChart: View {
    let data: [DailyCount]
    
    var body: some View {
        Chart {
            ForEach(data) { day in
                BarMark(
                    x: .value("Fecha", day.date, unit: .day),
                    y: .value("Audios", day.count)
                )
                .foregroundStyle(Color.mint.gradient)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: 0...(maxCount + 1))
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
    
    private var maxCount: Int {
        data.map(\.count).max() ?? 0
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
    }
}
