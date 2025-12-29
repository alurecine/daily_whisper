import SwiftUI

enum ToastStyle {
    case success
    case info
    case warning
    case error
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .info:    return .blue
        case .warning: return .orange
        case .error:   return .red
        }
    }
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let style: ToastStyle
    let title: String
    let message: String?
    let duration: TimeInterval
    
    init(style: ToastStyle, title: String, message: String? = nil, duration: TimeInterval = 2.2) {
        self.style = style
        self.title = title
        self.message = message
        self.duration = duration
    }
}

