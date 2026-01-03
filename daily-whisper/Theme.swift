import SwiftUI
import Combine

struct ThemeColors {
    // Fondos
    let background: Color          // Fondo general de pantallas
    let cardBackground: Color      // Fondo de tarjetas/superficies elevadas
    
    // Texto
    let cardTitle: Color           // Títulos dentro de cards
    let cardSubtitle: Color        // Subtítulos/descripciones en cards
    let textPrimary: Color         // Texto principal en pantallas
    let textSecondary: Color       // Texto secundario en pantallas
    
    // Acento
    let accent: Color              // Color de acento general
    
    // Botón de grabación
    let recordIdle: Color
    let recordRecording: Color
    
    // Utilitarios
    let chipBackground: Color      // Fondo de chips/filtros
    let separator: Color           // Líneas divisorias/strokes finos
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var colors: ThemeColors
    
    init() {
        // Único esquema “light” con colores sólidos explícitos
        self.colors = ThemeColors(
            // Fondos
            background: Color(red: 0.95, green: 0.96, blue: 0.98),          // #F2F5FA aprox
            cardBackground: Color.white,                                     // #FFFFFF
            
            // Texto (negros/grises sólidos)
            cardTitle: Color(red: 0.10, green: 0.12, blue: 0.14),            // #1A1F24
            cardSubtitle: Color(red: 0.45, green: 0.50, blue: 0.55),         // #73808C
            textPrimary: Color(red: 0.12, green: 0.15, blue: 0.18),          // #1F262E
            textSecondary: Color(red: 0.55, green: 0.60, blue: 0.66),        // #8C99A8
            
            // Acento (puedes mantener el de AppConfig si querés control central)
            accent: AppConfig.shared.ui.accentColor,                         // o Color(red: 0.00, green: 0.65, blue: 0.60) // #00A69A
            
            // Botón de grabación
            recordIdle: AppConfig.shared.ui.accentColor,                      // igual al acento por defecto
            recordRecording: Color(red: 0.93, green: 0.23, blue: 0.23),      // #ED3B3B
            
            // Utilitarios
            chipBackground: Color(red: 0.92, green: 0.94, blue: 0.96),       // #EAF0F5
            separator: Color(red: 0.85, green: 0.88, blue: 0.92)             // #D9E0EA
        )
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
