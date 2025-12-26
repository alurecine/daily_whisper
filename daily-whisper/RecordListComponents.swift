import SwiftUI

struct DayHeader: View {
    let date: Date
    var body: some View {
        Text(formatted(date))
            .font(.headline)
            .foregroundColor(.secondary)
    }
    private func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
}

struct CardRow: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    let isDisabled: Bool
    let onDelete: () -> Void
    
    private var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    // Mapa de emociones y orden centralizados
    private var emotionMap: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !isDisabled {
                    player.toggle(entry: entry)
                }
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(primaryText)
                        .font(.body)
                    
                    // Badge de emoción si existe
                    if let emotion = AppConfig.Emotion.from(raw: entry.emotion),
                       let item = emotionMap[emotion] {
                        EmotionBadge(title: emotion.title, color: item.color, imageName: item.imageName)
                    }
                }
                
                Text(secondaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
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

private struct EmotionBadge: View {
    let title: String
    let color: Color
    let imageName: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityLabel("Emoción: \(title)")
    }
}

