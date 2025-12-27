//
//  DashboardView.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI
internal import CoreData
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
    
    // ÚNICA FUENTE DE VERDAD: Usuario desde Core Data (traer 1)
    @FetchRequest(
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var users: FetchedResults<User>
    
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
    
    // Usuario actual (si no existe, placeholder)
    private var currentUser: User? {
        users.first
    }
    private var displayName: String {
        if let name = currentUser?.value(forKey: "name") as? String, !name.isEmpty {
            return name
        }
        return "Tu nombre"
    }
    private var avatarImage: Image {
        if let data = currentUser?.value(forKey: "profileImageData") as? Data,
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.crop.circle.fill")
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header de bienvenida + avatar + badge de plan
                HStack(alignment: .center, spacing: 12) {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hola, \(displayName)")
                            .font(.title2.bold())
                        Text("Qué bueno verte por aquí")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    PlanBadge(role: AppConfig.shared.subscription.role, accent: accent)
                }
                .padding(.horizontal, 16)
                
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
                
                // Sección: Recomendaciones
                SectionHeader("Recomendaciones")
                RecommendationsCarousel(items: recommendations) { item in
                    selectedRecommendation = item
                }
                
                // Sección: Resumen (gráfico) visible solo para PRO o ILIMITADO
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("Resumen de actividad")
                    VStack {
                        if AppConfig.shared.subscription.role == .pro || AppConfig.shared.subscription.role == .unlimited {
                            Picker("", selection: $chartRange) {
                                Text("S").tag(ChartRange.week)
                                Text("M").tag(ChartRange.month)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 160)
                            
                            ActivityChart(data: chartData, range: chartRange)
                                .frame(height: 220)
                                .padding(.top, 4)
                        } else {
                            // Bloqueado para usuarios Normal
                            LockedStatsCard(accent: accent) {
                                showPlans = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(AppConfig.shared.ui.backgroundColor)
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
        case .week:
            return dailyActivityLast7d
        case .month:
            return dailyActivityLast30d
        }
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
            .fill(AppConfig.shared.ui.cardBackgroundColor)
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
                .fill(AppConfig.shared.ui.cardBackgroundColor)
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
                .fill(AppConfig.shared.ui.cardBackgroundColor)
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
        .background(AppConfig.shared.ui.cardBackgroundColor)
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
                .fill(AppConfig.shared.ui.cardBackgroundColor)
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
                .fill(AppConfig.shared.ui.cardBackgroundColor)
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
                .background(AppConfig.shared.ui.cardBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var xUnit: Calendar.Component {
        switch range {
        case .week: return .day
        case .month: return .day
        }
    }
    
    private var maxY: Int {
        data.map(\.count).max() ?? 0
    }
}

// MARK: - Badge de plan actual

private struct PlanBadge: View {
    let role: AppConfig.UserRole
    let accent: Color
    
    var body: some View {
        switch role {
        case .normal:
            Text("Normal")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        case .pro:
            Text("PRO")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(accent.opacity(0.15))
                .foregroundColor(accent)
                .clipShape(Capsule())
        case .unlimited:
            Text("ILIMITADO")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.15))
                .foregroundColor(.purple)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Locked stats card

private struct LockedStatsCard: View {
    let accent: Color
    let onSubscribe: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(accent)
                .padding(.top, 16)
            Text("Estadísticas disponibles en PRO")
                .font(.headline)
            Text("Suscríbete para ver tus estadísticas semanales y mensuales.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button {
                onSubscribe()
            } label: {
                Text("Ver planes")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppConfig.shared.ui.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        DashboardView(selectedTab: .constant(.dashboard))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
    }
}
