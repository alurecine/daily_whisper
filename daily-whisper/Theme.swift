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
    
    // Nuevos: colores del botón de grabación
    let recordIdle: Color
    let recordRecording: Color
}

enum AppTheme {
    case light
    case dark
    
    var colors: ThemeColors {
        switch self {
        case .light:
            return ThemeColors(
                background: AppConfig.shared.ui.backgroundColor,
                cardBackground: .white,
                cardTitle: Color(.label),
                cardSubtitle: Color(.secondaryLabel),
                textPrimary: .primary,
                textSecondary: .secondary,
                accent: AppConfig.shared.ui.accentColor,
                recordIdle: AppConfig.shared.ui.accentColor, // por defecto usamos el acento
                recordRecording: .red // rojo estándar; puedes ajustar si quieres otro tono
            )
        case .dark:
            return ThemeColors(
                background: AppConfig.shared.ui.backgroundColor,
                cardBackground: .black.opacity(0.5),
                cardTitle: .white,
                cardSubtitle: Color(.secondaryLabel),
                textPrimary: .white,
                textSecondary: .secondary,
                accent: AppConfig.shared.ui.accentColor,
                recordIdle: AppConfig.shared.ui.accentColor,
                recordRecording: .red
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
            if let scheme {
                return scheme == .dark ? .dark : .light
            } else {
                return .light
            }
        } else {
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
