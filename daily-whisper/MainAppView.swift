import SwiftUI

struct MainAppView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
        .background(AppConfig.shared.ui.backgroundColor)
    }
}
