// KeyboardDismissOnTap.swift
import SwiftUI
import UIKit

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.endEditing()
                }
            )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
