//
//  PlansView.swift
//  daily-whisper
//
//  Created by Alan Recine on 24/12/2025.
//

import SwiftUI

struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    @State private var selectedPlan: Plan = .proMonthly
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    enum Plan: String, CaseIterable, Identifiable {
        case proMonthly, proYearly, unlimited
        var id: String { rawValue }
        var title: String {
            switch self {
            case .proMonthly: return "PRO Mensual"
            case .proYearly: return "PRO Anual"
            case .unlimited: return "ILIMITADO"
            }
        }
        var price: String {
            switch self {
            case .proMonthly: return "US$ 3.99/mes"
            case .proYearly: return "US$ 29.99/año"
            case .unlimited: return "US$ 59.99/año"
            }
        }
        var footnote: String {
            switch self {
            case .proMonthly: return "Cancela cuando quieras."
            case .proYearly: return "Ahorra 37% vs mensual."
            case .unlimited: return "Audios sin límite. 2 minutos por audio."
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Elige tu plan")
                    .font(.largeTitle.bold())
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                BenefitRow(
                    icon: "mic.fill",
                    title: "Graba más por día",
                    subtitle: "Hasta 5 audios diarios en PRO. Sin límite en ILIMITADO.",
                    accent: accent,
                    theme: theme
                )
                BenefitRow(
                    icon: "timer",
                    title: "Duración por audio",
                    subtitle: "30s Normal, 60s PRO, 120s ILIMITADO",
                    accent: accent,
                    theme: theme
                )
                BenefitRow(
                    icon: "tray.full.fill",
                    title: "Más historial",
                    subtitle: "7/30/90 días según plan",
                    accent: accent,
                    theme: theme
                )
                
                VStack(spacing: 12) {
                    ForEach(Plan.allCases) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            accent: accent,
                            theme: theme
                        )
                        .onTapGesture {
                            withAnimation(.smooth) { selectedPlan = plan }
                        }
                    }
                }
                .padding(.top, 8)
                
                Button {
                    switch selectedPlan {
                    case .proMonthly, .proYearly:
                        AppConfig.shared.subscription.role = .pro
                        storedUserRoleRaw = AppConfig.UserRole.pro.rawValue
                    case .unlimited:
                        AppConfig.shared.subscription.role = .unlimited
                        storedUserRoleRaw = AppConfig.UserRole.unlimited.rawValue
                    }
                    dismiss()
                } label: {
                    Text("Suscribirme a \(selectedPlan.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                
                Button { dismiss() } label: {
                    Text("Más tarde")
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .navigationTitle("Planes y precios")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.colors.background)
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.colors.cardTitle)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.cardSubtitle)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.colors.cardBackground)
        )
    }
}

private struct PlanCard: View {
    let plan: PlansView.Plan
    let isSelected: Bool
    let accent: Color
    let theme: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)
                    .foregroundColor(theme.colors.cardTitle)
                Text(plan.price)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.cardSubtitle)
                Text(plan.footnote)
                    .font(.caption2)
                    .foregroundColor(theme.colors.cardSubtitle)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accent)
                    .font(.title3)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? accent : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 0.5)
        )
    }
}
