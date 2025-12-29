import SwiftUI

struct ToastOverlay: ViewModifier {
    @ObservedObject var center: ToastCenter
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let toast = center.current {
                VStack(spacing: 0) {
                    // Safe area top spacing
                    Color.clear
                        .frame(height: 8)
                        .accessibilityHidden(true)
                    
                    ToastView(toast: toast) {
                        center.hideCurrent()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: center.current?.id)
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
        }
    }
}

extension View {
    func toastOverlay(_ center: ToastCenter = .shared) -> some View {
        modifier(ToastOverlay(center: center))
    }
}

