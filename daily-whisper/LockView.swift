//
//  LockView.swift
//  daily-whisper
//
//  Created by Alan Recine on 23/12/2025.
//

import SwiftUI

struct LockView: View {
    var title: String = "Protegido"
    var message: String = "Autentícate para continuar"
    let onUnlock: () -> Void
    let onUsePasscode: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                Button {
                    onUnlock()
                } label: {
                    Label("Face ID", systemImage: "faceid")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    onUsePasscode()
                } label: {
                    Label("Usar código", systemImage: "key.fill")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LockView(onUnlock: {}, onUsePasscode: {})
}

