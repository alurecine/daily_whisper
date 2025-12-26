import SwiftUI
import Combine

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()
    
    // Cola de toasts pendientes
    @Published private(set) var queue: [Toast] = []
    // Toast actual visible
    @Published private(set) var current: Toast?
    
    private var isShowing = false
    
    private init() {}
    
    func show(_ toast: Toast) {
        queue.append(toast)
        processQueue()
    }
    
    func success(_ title: String, message: String? = nil, duration: TimeInterval = 2.2) {
        show(Toast(style: .success, title: title, message: message, duration: duration))
    }
    func info(_ title: String, message: String? = nil, duration: TimeInterval = 2.2) {
        show(Toast(style: .info, title: title, message: message, duration: duration))
    }
    func warning(_ title: String, message: String? = nil, duration: TimeInterval = 2.5) {
        show(Toast(style: .warning, title: title, message: message, duration: duration))
    }
    func error(_ title: String, message: String? = nil, duration: TimeInterval = 2.8) {
        show(Toast(style: .error, title: title, message: message, duration: duration))
    }
    
    private func processQueue() {
        guard !isShowing, current == nil, !queue.isEmpty else { return }
        isShowing = true
        current = queue.removeFirst()
        
        let delay = current?.duration ?? 2.2
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self?.hideCurrent()
        }
    }
    
    func hideCurrent() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            current = nil
        }
        isShowing = false
        // Procesar siguiente en cola
        processQueue()
    }
}

