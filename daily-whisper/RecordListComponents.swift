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
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    private var emotionMap: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    private var emotion: AppConfig.Emotion? { AppConfig.Emotion.from(raw: entry.emotion) }
    private var emotionItem: AppConfig.UI.EmotionItem? {
        guard let e = emotion else { return nil }
        return emotionMap[e]
    }
    
    private var minTagWidth: CGFloat { hSizeClass == .regular ? 180 : 140 }
    private var maxTagWidth: CGFloat { hSizeClass == .regular ? 280 : 200 }
    private var tagWidthRatio: CGFloat { hSizeClass == .regular ? 0.42 : 0.40 }
    
    var body: some View {
        GeometryReader { proxy in
            let proposed = proxy.size.width * tagWidthRatio
            let tagWidth = min(max(proposed, minTagWidth), maxTagWidth)
            
            HStack(spacing: 12) {
                Button {
                    if !isDisabled { player.toggle(entry: entry) }
                } label: {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                
                EmotionLeadingTag(
                    title: emotion?.title,
                    color: emotionItem?.color ?? .gray,
                    imageName: emotionItem?.imageName
                )
                .frame(width: tagWidth, alignment: .center)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(primaryText).font(.body).lineLimit(1).truncationMode(.tail)
                    Text(secondaryText).font(.caption).foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppConfig.shared.ui.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
        }
        .frame(height: 72)
    }
    
    private var primaryText: String {
        let f = DateFormatter()
        f.timeStyle = .short
        let time = f.string(from: entry.date ?? Date())
        return "\(time)"
    }
    private var secondaryText: String {
        "\(Int(entry.duration))s"
    }
}

private struct EmotionLeadingTag: View {
    let title: String?
    let color: Color
    let imageName: String?
    
    var body: some View {
        HStack(spacing: 8) {
            if let imageName {
                Image(imageName).resizable().scaledToFit()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityLabel(title != nil ? "Emoción: \(title!)" : "Emoción")
    }
}
