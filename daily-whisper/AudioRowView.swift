import Foundation
import SwiftUI

struct AudioRowView: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.themeManager) private var theme
    
    private var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    private var emotion: AppConfig.Emotion? {
        AppConfig.Emotion.from(raw: entry.emotion)
    }
    private var emotionItem: AppConfig.UI.EmotionItem? {
        guard let e = emotion else { return nil }
        return AppConfig.shared.ui.emotions[e]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            EmotionLeadingTag(
                title: emotion?.title,
                color: emotionItem?.color ?? .gray,
                imageName: emotionItem?.imageName
            )
            
            Button {
                player.toggle(entry: entry)
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(primaryText)
                    .font(.body)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer()
            
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
                .fill(theme.colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.colors.separator, lineWidth: 0.5)
        )
    }
    
    private var primaryText: String {
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
                    .frame(width: 28, height: 28)
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
