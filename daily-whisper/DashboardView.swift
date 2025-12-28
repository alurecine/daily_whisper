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
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.themeManager) private var theme
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AudioEntry.date, ascending: false)
        ],
        animation: .default
    )
    private var allEntries: FetchedResults<AudioEntry>
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var users: FetchedResults<User>
    
    @StateObject private var player = AudioPlayerManager()
    @Binding var selectedTab: AppTab
    @State private var selectedRecommendation: RecommendationItem?
    @State private var showPlans = false
    
    private var accent: Color { theme.colors.accent }
    
    enum ChartRange: String, CaseIterable, Identifiable {
        case week = "Semana"
        case month = "Mes"
        var id: String { rawValue }
    }
    @State private var chartRange: ChartRange = .month
    
    private let news: [NewsItem] = [
        .init(title: "Nueva función de grabación", subtitle: "Ahora puedes grabar hasta 30s con mejor calidad.", imageSystemName: "mic.circle.fill", tint: .mint),
        .init(title: "Mejoras en el reproductor", subtitle: "Controles más claros y correcciones de errores.", imageSystemName: "play.circle.fill", tint: .blue),
        .init(title: "Sincronización en camino", subtitle: "Muy pronto podrás sincronizar tus audios.", imageSystemName: "icloud.and.arrow.up.fill", tint: .purple),
        .init(title: "Estadísticas semanales", subtitle: "Estamos preparando métricas útiles para ti.", imageSystemName: "chart.bar.xaxis", tint: .orange)
    ]
    
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
    
    private var lastWeekEntries: [AudioEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-7*24*3600)
        return allEntries.filter { entry in
            guard let d = entry.date else { return false }
            return d >= sevenDaysAgo
        }
    }
    
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
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Qué bueno verte por aquí")
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                    PlanBadge(role: AppConfig.shared.subscription.role, accent: accent)
                }
                .padding(.horizontal, 16)
                
                if AppConfig.shared.subscription.role == .normal {
                    PromoProCard(accent: accent, onSubscribe: { showPlans = true })
                        .padding(.horizontal, 16)
                }
                
                SectionHeader("Novedades", titleColor: theme.colors.textPrimary)
                NewsCarousel(items: news, theme: theme)
                
                SectionHeader("Tu semana", titleColor: theme.colors.textPrimary)
                if lastWeekEntries.isEmpty {
                    PlaceholderCard(height: 120, theme: theme)
                        .overlay(
                            Text("Aún no hay audios esta semana")
                                .font(.subheadline)
                                .foregroundColor(theme.colors.cardSubtitle)
                        )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(lastWeekEntries) { entry in
                                MiniWeekCard(entry: entry, theme: theme) {
                                    selectedTab = .record
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                SectionHeader("Recomendaciones", titleColor: theme.colors.textPrimary)
                RecommendationsCarousel(items: recommendations, theme: theme) { item in
                    selectedRecommendation = item
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("Resumen de actividad", titleColor: theme.colors.textPrimary)
                    VStack {
                        if AppConfig.shared.subscription.role == .pro || AppConfig.shared.subscription.role == .unlimited {
                            Picker("", selection: $chartRange) {
                                Text("S").tag(ChartRange.week)
                                Text("M").tag(ChartRange.month)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 160)
                            
                            ActivityChart(data: chartData, range: chartRange, theme: theme)
                                .frame(height: 220)
                                .padding(.top, 4)
                        } else {
                            LockedStatsCard(accent: accent, theme: theme) {
                                showPlans = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(theme.colors.background)
        .sheet(item: $selectedRecommendation) { item in
            RecommendationDetailSheet(item: item, theme: theme)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlans) {
            NavigationStack {
                PlansView()
            }
            .presentationDetents([.large])
        }
        .tint(theme.colors.accent)
    }
    
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
    let titleColor: Color
    init(_ title: String, titleColor: Color) { self.title = title; self.titleColor = titleColor }
    
    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(titleColor)
            .padding(.horizontal, 16)
    }
}

private struct PlaceholderCard: View {
    var height: CGFloat = 140
    let theme: ThemeManager
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(theme.colors.cardBackground)
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
    let theme: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(items) { item in
                    NewsCard(item: item, theme: theme)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem
    let theme: ThemeManager
    
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
                    .foregroundColor(theme.colors.cardTitle)
                    .lineLimit(2)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.cardSubtitle)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.colors.cardBackground)
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
    let theme: ThemeManager
    let onTap: (RecommendationItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(items) { item in
                    RecommendationCard(item: item, theme: theme)
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
    let theme: ThemeManager
    
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
                    .foregroundColor(theme.colors.cardTitle)
                    .lineLimit(2)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.cardSubtitle)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.colors.cardBackground)
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
    let theme: ThemeManager
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
                        .foregroundColor(theme.colors.cardTitle)
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.cardSubtitle)
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
                    .foregroundColor(theme.colors.cardTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
        .background(theme.colors.cardBackground)
    }
}

// MARK: - Promo PRO Card
private struct PromoProCard: View {
    let accent: Color
    @Environment(\.themeManager) private var theme
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
                    .foregroundColor(theme.colors.cardTitle)
                Text("Graba hasta 5 audios diarios y conserva 30 días de historial.")
                    .font(.caption)
                    .foregroundColor(theme.colors.cardSubtitle)
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
                .fill(theme.colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - MiniWeekCard

private struct MiniWeekCard: View {
    let entry: AudioEntry
    let theme: ThemeManager
    let onTap: () -> Void
    
    private var formattedDay: String {
        let f = DateFormatter()
        f.dateFormat = "E d"
        return f.string(from: entry.date ?? Date())
    }
    
    private var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: entry.date ?? Date())
    }
    
    private var durationText: String { "\(Int(entry.duration)) s" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDay)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.colors.cardTitle)
                Spacer()
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(theme.colors.cardSubtitle)
            }
            HStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(durationText)
                    .font(.caption2)
                    .foregroundColor(theme.colors.cardSubtitle)
            }
            HStack(spacing: 4) {
                Image(systemName: "mic.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Audio")
                    .font(.caption2)
                    .foregroundColor(theme.colors.cardSubtitle)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(width: 150, height: 80, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.colors.cardBackground)
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

// MARK: - Gráfico

private struct TimeCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct ActivityChart: View {
    let data: [TimeCount]
    let range: DashboardView.ChartRange
    let theme: ThemeManager
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Fecha", point.date, unit: xUnit),
                    y: .value("Audios", point.count)
                )
                .foregroundStyle(theme.colors.accent.gradient)
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
                .background(theme.colors.cardBackground)
                .cornerRadius(12)
        }
    }
    
    private var xUnit: Calendar.Component {
        switch range {
        case .week: return .day
        case .month: return .day
        }
    }
    
    private var maxY: Int { data.map(\.count).max() ?? 0 }
}

// MARK: - Locked stats card

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

private struct LockedStatsCard: View {
    let accent: Color
    let theme: ThemeManager
    let onSubscribe: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(accent)
                .padding(.top, 16)
            Text("Estadísticas disponibles en PRO")
                .font(.headline)
                .foregroundColor(theme.colors.cardTitle)
            Text("Suscríbete para ver tus estadísticas semanales y mensuales.")
                .font(.subheadline)
                .foregroundColor(theme.colors.cardSubtitle)
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
                .fill(theme.colors.cardBackground)
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
