import SwiftUI

struct MainAppView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.themeManager) private var theme
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Inicio", systemImage: "house.fill") }
            .tag(AppTab.dashboard)
            
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Audios", systemImage: "waveform") }
            .tag(AppTab.record)
        }
        .background(theme.colors.background)
    }
}
