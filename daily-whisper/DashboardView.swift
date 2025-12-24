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
    
    // Player local (si lo necesitas en el futuro)
    @StateObject private var player = AudioPlayerManager()
    
    // Binding a la pestaña seleccionada para poder saltar a la lista de audios
    @Binding var selectedTab: AppTab
    
    // Estado para sheet de recomendaciones
    @State private var selectedRecommendation: RecommendationItem?
    
    // Control de navegación a PlansView
    @State private var showPlans = false
    
    // Color de acento centralizado
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    // Rango seleccionado para el gráfico (local a la sesión)
    enum ChartRange: String, CaseIterable, Identifiable {
        case day = "Día"
        case week = "Semana"
        case month = "Mes"
        var id: String { rawValue }
    }
    @State private var chartRange: ChartRange = .month
    
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
    
    // Últimos 7 días para "Tu semana"
    private var lastWeekEntries: [AudioEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-7*24*3600)
        return allEntries.filter { entry in
            guard let d = entry.date else { return false }
            return d >= sevenDaysAgo
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Promo PRO (solo usuarios normales)
                if AppConfig.shared.subscription.role == .normal {
                    PromoProCard(accent: accent) {
                        showPlans = true
                    }
                    .padding(.horizontal, 16)
                }
                
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
                        HStack(spacing: 10) {
                            ForEach(lastWeekEntries) { entry in
                                MiniWeekCard(entry: entry) {
                                    // Al tocar cualquier card, saltamos a la pestaña de lista de audios
                                    selectedTab = .record
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Sección: Recomendaciones (restaurada)
                SectionHeader("Recomendaciones")
                RecommendationsCarousel(items: recommendations) { item in
                    selectedRecommendation = item
                }
                
                // Sección: Resumen (gráfico) con Picker debajo del título
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("Resumen de actividad")
                    Picker("", selection: $chartRange) {
                        Text("D").tag(ChartRange.day)
                        Text("S").tag(ChartRange.week)
                        Text("M").tag(ChartRange.month)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                    
                    ActivityChart(data: chartData, range: chartRange)
                        .frame(height: 220)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
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
        .sheet(isPresented: $showPlans) {
            NavigationStack {
                PlansView()
            }
            .presentationDetents([.large])
        }
    }
    
    // MARK: - Datos del gráfico según rango
    
    private var chartData: [TimeCount] {
        switch chartRange {
        case .day:
            return hourlyActivityLast24h
        case .week:
            return dailyActivityLast7d
        case .month:
            return dailyActivityLast30d
        }
    }
    
    private var hourlyActivityLast24h: [TimeCount] {
        let hours = (0..<24).map { offset -> Date in
            let date = Date().addingTimeInterval(-Double(offset) * 3600)
            let start = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? date
            return start
        }
        var counts: [Date: Int] = [:]
        for entry in allEntries {
            guard let d = entry.date else { continue }
            // Redondear a la hora exacta (minuto y segundo en 0)
            let hour = Calendar.current.component(.hour, from: d)
            let startHour = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: d) ?? d
            if let minHour = hours.last, startHour >= minHour {
                counts[startHour, default: 0] += 1
            }
        }
        let sorted = hours.sorted()
        return sorted.map { TimeCount(date: $0, count: counts[$0, default: 0]) }
    }
    
    private var dailyActivityLast7d: [TimeCount] {
        let days = (0..<7).map { offset -> Date in
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
        let sorted = days.sorted()
        return sorted.map { TimeCount(date: $0, count: counts[$0, default: 0]) }
    }
    
    private var dailyActivityLast30d: [TimeCount] {
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
        let sorted = days.sorted()
        return sorted.map { TimeCount(date: $0, count: counts[$0, default: 0]) }
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

// MARK: - Promo PRO Card (usa accent centralizado)
private struct PromoProCard: View {
    let accent: Color
    let onSubscribe: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Pásate a PRO")
                    .font(.headline)
                Text("Graba hasta 5 audios diarios y conserva 30 días de historial.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
            Spacer()
            Button {
                onSubscribe()
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
        .padding(14)
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

// MARK: - Mini card para "Tu semana"

private struct MiniWeekCard: View {
    let entry: AudioEntry
    let onTap: () -> Void
    
    private var formattedDay: String {
        let f = DateFormatter()
        f.dateFormat = "E d" // ej: "Lun 23"
        return f.string(from: entry.date ?? Date())
    }
    
    private var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short // ej: "14:32"
        return f.string(from: entry.date ?? Date())
    }
    
    private var durationText: String {
        "\(Int(entry.duration)) s"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Encabezado: día y hora
            HStack {
                Text(formattedDay)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Ícono + duración
            HStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(durationText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Pie: pequeño badge (sin Spacer para compactar)
            HStack(spacing: 4) {
                Image(systemName: "mic.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Audio")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(width: 150, height: 80, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Gráfico de actividad adaptado a rango

private struct TimeCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct ActivityChart: View {
    let data: [TimeCount]
    let range: DashboardView.ChartRange
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Fecha", point.date, unit: xUnit),
                    y: .value("Audios", point.count)
                )
                .foregroundStyle(AppConfig.shared.ui.accentColor.gradient)
            }
        }
        .chartXAxis {
            switch range {
            case .day:
                AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                }
            case .week:
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            case .month:
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: 0...(maxY + 1))
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
    
    private var xUnit: Calendar.Component {
        switch range {
        case .day: return .hour
        case .week, .month: return .day
        }
    }
    
    private var maxY: Int {
        data.map(\.count).max() ?? 0
    }
}

#Preview {
    NavigationStack {
        DashboardView(selectedTab: .constant(.dashboard))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
    }
}
