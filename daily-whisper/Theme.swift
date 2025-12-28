import SwiftUI
import Combine

struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let cardTitle: Color
    let cardSubtitle: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
}

enum AppTheme {
    case light
    case dark
    
    var colors: ThemeColors {
        switch self {
        case .light:
            return ThemeColors(
                background: AppConfig.shared.ui.backgroundColor, // ya definido
                cardBackground: .white,
                cardTitle: Color(.label),          // alto contraste sobre blanco
                cardSubtitle: Color(.secondaryLabel),
                textPrimary: .primary,
                textSecondary: .secondary,
                accent: AppConfig.shared.ui.accentColor
            )
        case .dark:
            return ThemeColors(
                background: AppConfig.shared.ui.backgroundColor, // puedes personalizar
                cardBackground: .white,           // si quieres, cámbialo a Color(.secondarySystemBackground)
                cardTitle: .black,         // importantísimo para que se vea sobre blanco
                cardSubtitle: .black.opacity(0.6),
                textPrimary: .primary,
                textSecondary: .secondary,
                accent: AppConfig.shared.ui.accentColor
            )
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var colors: ThemeColors
    
    @AppStorage("profile.useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("profile.forceDarkMode") private var forceDarkMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(initialScheme: ColorScheme? = nil) {
        // 1) Initialize all stored properties without touching @AppStorage
        self.colors = AppTheme.light.colors
        
        // 2) Now self is initialized; it’s safe to read @AppStorage-backed properties
        let theme = Self.resolveTheme(
            useSystem: self.useSystemAppearance,
            forceDark: self.forceDarkMode,
            scheme: initialScheme
        )
        self.colors = theme.colors
    }
    
    func update(for scheme: ColorScheme?) {
        let theme = Self.resolveTheme(
            useSystem: self.useSystemAppearance,
            forceDark: self.forceDarkMode,
            scheme: scheme
        )
        self.colors = theme.colors
    }
    
    private static func resolveTheme(useSystem: Bool, forceDark: Bool, scheme: ColorScheme?) -> AppTheme {
        if useSystem {
            // Si el usuario quiere el sistema, usamos el esquema actual (si no hay, asumimos light)
            if let scheme {
                return scheme == .dark ? .dark : .light
            } else {
                return .light
            }
        } else {
            // Usuario fuerza modo
            return forceDark ? .dark : .light
        }
    }
}

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
