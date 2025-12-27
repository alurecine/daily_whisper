//
//  AudioRowView.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import SwiftUI

struct AudioRowView: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    var onDelete: (() -> Void)? = nil
    
    private var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    // Emociones centralizadas
    private var emotion: AppConfig.Emotion? {
        AppConfig.Emotion.from(raw: entry.emotion)
    }
    private var emotionItem: AppConfig.UI.EmotionItem? {
        guard let e = emotion else { return nil }
        return AppConfig.shared.ui.emotions[e]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Emotion tag grande al inicio (izquierda)
            EmotionLeadingTag(
                title: emotion?.title,
                color: emotionItem?.color ?? .gray,
                imageName: emotionItem?.imageName
            )
            
            // Play/Stop
            Button {
                player.toggle(entry: entry)
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            // Texto principal
            VStack(alignment: .leading, spacing: 6) {
                Text(primaryText)
                    .font(.body)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer()
            
            // Borrar
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }
    
    private var primaryText: String {
        // Consistencia con CardRow: "Audio • HH:mm"
        let f = DateFormatter()
        f.timeStyle = .short
        let time = f.string(from: entry.date ?? Date())
        return "Audio • \(time)"
    }
    private var secondaryText: String {
        let duration = Int(entry.duration)
        return "\(duration)s"
    }
}

private struct EmotionLeadingTag: View {
    let title: String?
    let color: Color
    let imageName: String?
    
    var body: some View {
        HStack(spacing: 8) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28) // más grande y claro
                    .accessibilityHidden(true)
            }
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityLabel(title != nil ? "Emoción: \(title!)" : "Emoción")
    }
}
