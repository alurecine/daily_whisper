//
//  EmotionFilterChips.swift
//  daily-whisper
//
//  Created by Alan Recine on 26/12/2025.
//

import SwiftUI

struct EmotionFilterChips: View {
    @Binding var selected: AppConfig.Emotion?
    
    private var accent: Color { AppConfig.shared.ui.accentColor }
    private var order: [AppConfig.Emotion] { AppConfig.shared.ui.emotionOrder }
    private var map: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Todos" chip
                Chip(
                    isSelected: selected == nil,
                    imageName: nil,
                    title: "Todos",
                    tint: accent
                ) {
                    withAnimation(.easeInOut) { selected = nil }
                }
                
                ForEach(order, id: \.self) { emotion in
                    let item = map[emotion]
                    Chip(
                        isSelected: selected == emotion,
                        imageName: item?.imageName,
                        title: emotion.title,
                        tint: item?.color ?? .gray
                    ) {
                        withAnimation(.easeInOut) { selected = emotion }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct Chip: View {
    let isSelected: Bool
    let imageName: String?
    let title: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? tint : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .overlay(
                Capsule()
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    private var background: some ShapeStyle {
        isSelected ? AnyShapeStyle(tint.opacity(0.18)) : AnyShapeStyle(Color(.secondarySystemBackground))
    }
    private var border: Color {
        isSelected ? tint : Color.black.opacity(0.08)
    }
}

#Preview {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State var selected: AppConfig.Emotion? = nil
    var body: some View {
        EmotionFilterChips(selected: $selected)
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}

