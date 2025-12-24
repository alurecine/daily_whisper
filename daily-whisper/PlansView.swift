//
//  PlansView.swift
//  daily-whisper
//
//  Created by Alan Recine on 24/12/2025.
//

import SwiftUI

struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Persistencia del rol para toda la app
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    
    @State private var selectedPlan: Plan = .proMonthly
    
    // Fuente única de color de acento
    private var accent: Color { AppConfig.shared.ui.accentColor }
    
    enum Plan: String, CaseIterable, Identifiable {
        case proMonthly
        case proYearly
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .proMonthly: return "PRO Mensual"
            case .proYearly: return "PRO Anual"
            }
        }
        
        var price: String {
            switch self {
            case .proMonthly: return "US$ 3.99/mes"
            case .proYearly: return "US$ 29.99/año"
            }
        }
        
        var footnote: String {
            switch self {
            case .proMonthly: return "Cancela cuando quieras."
            case .proYearly: return "Ahorra 37% vs mensual."
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Elige tu plan PRO")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                BenefitRow(icon: "mic.fill", title: "Graba más por día", subtitle: "Hasta 5 audios diarios", accent: accent)
                BenefitRow(icon: "tray.full.fill", title: "Más historial", subtitle: "Conserva tus audios por 30 días", accent: accent)
                BenefitRow(icon: "waveform", title: "Mejoras futuras", subtitle: "Acceso prioritario a novedades", accent: accent)
                
                VStack(spacing: 12) {
                    ForEach(Plan.allCases) { plan in
                        PlanCard(plan: plan, isSelected: selectedPlan == plan, accent: accent)
                            .onTapGesture { selectedPlan = plan }
                    }
                }
                .padding(.top, 8)
                
                Button {
                    // Aquí integrarás tu flujo de compra (StoreKit)
                    // Simulación: marcar usuario como PRO y persistirlo
                    AppConfig.shared.subscription.role = .pro
                    storedUserRoleRaw = AppConfig.UserRole.pro.rawValue
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
                
                Button {
                    dismiss()
                } label: {
                    Text("Más tarde")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .navigationTitle("Planes y precios")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct PlanCard: View {
    let plan: PlansView.Plan
    let isSelected: Bool
    let accent: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title).font(.headline)
                Text(plan.price).font(.subheadline).foregroundColor(.secondary)
                Text(plan.footnote).font(.caption2).foregroundColor(.secondary)
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
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? accent : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        PlansView()
    }
}
