import SwiftUI

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
                    .environment(\.managedObjectContext, viewContext)
            } else {
                OnboardingView()
                    .onChange(of: hasCompletedOnboarding) { _, newValue in
                        // Cuando se complete el onboarding, cambiará automáticamente a la app
                        if newValue {
                            // No hace falta nada más; el if del body se reevalúa
                        }
                    }
            }
        }
    }
}
