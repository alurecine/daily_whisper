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
    @Environment(\.themeManager) private var theme
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
                    .navigationBarBackButtonHidden(true)
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(AppTab.dashboard)
            
            NavigationStack {
                HomeView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Grabar", systemImage: "mic.circle.fill")
            }
            .tag(AppTab.record)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle.fill")
            }
            .tag(AppTab.profile)
        }
        .tint(theme.colors.accent)
    }
}

#Preview {
    RootTabView()
}
