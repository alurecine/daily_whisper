//
//  RootTabView.swift
//  daily-whisper
//
//  Created by Alan Recine on 22/12/2025.
//

import SwiftUI

enum AppTab: Int {
    case dashboard = 0
    case record = 1
    case profile = 2
}

struct RootTabView: View {
    // Ya no usamos AppStorage para el color de acento
    @AppStorage("profile.useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("profile.forceDarkMode") private var forceDarkMode: Bool = false
    
    // SceneStorage mantiene el estado mientras la escena viva, pero no entre lanzamientos
    @SceneStorage("ui.selectedTab.scene") private var selectedTabRaw: Int = AppTab.dashboard.rawValue
    
    private var selectedTab: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: selectedTabRaw) ?? .dashboard },
            set: { selectedTabRaw = $0.rawValue }
        )
    }
    
    var body: some View {
        TabView(selection: selectedTab) {
            NavigationStack {
                // Pasamos el binding a DashboardView
                DashboardView(selectedTab: selectedTab)
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(AppTab.dashboard)
            
            NavigationStack {
                HomeView()
                    .navigationTitle("Grabar")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Grabar", systemImage: "mic.circle.fill")
            }
            .tag(AppTab.record)
            
            NavigationStack {
                ProfileView()
                    .navigationTitle("Perfil")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle.fill")
            }
            .tag(AppTab.profile)
        }
        .tint(AppConfig.shared.ui.accentColor) // Color de acento global desde AppConfig
        .modifier(GlobalColorSchemeApplier(useSystemAppearance: useSystemAppearance, forceDarkMode: forceDarkMode))
    }
}

// ViewModifier global para esquema de color
struct GlobalColorSchemeApplier: ViewModifier {
    let useSystemAppearance: Bool
    let forceDarkMode: Bool
    
    func body(content: Content) -> some View {
        if useSystemAppearance {
            content
        } else {
            content.preferredColorScheme(forceDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    RootTabView()
}
