import SwiftUI

struct IntegratedRecordingOverlay: View {
    @Binding var isPresented: Bool
    let isDisabled: Bool
    @ObservedObject var recorder: AudioRecorderManager
    let onFinish: (URL, Double, AppConfig.Emotion) -> Void
    
    @State private var tempURL: URL?
    @State private var selectedEmotion: AppConfig.Emotion = .angelical
    
    @Environment(\.themeManager) private var theme
    
    private var accent: Color { theme.colors.accent }
    private var maxDuration: TimeInterval { AppConfig.shared.audio.maxRecordingDuration }
    private var emotionOrder: [AppConfig.Emotion] { AppConfig.shared.ui.emotionOrder }
    private var emotionMap: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    if !recorder.isRecording {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        if recorder.isRecording {
                            stopRecordingAndMaybeSave(save: false)
                        }
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                Text(timeString(recorder.currentTime) + " / " + timeString(maxDuration))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                RecordButtonView(recorder: recorder) { url, duration in
                    tempURL = url
                }
                .allowsHitTesting(!isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emotionOrder, id: \.rawValue) { emotion in
                            let item = emotionMap[emotion]
                            EmotionChip(
                                isSelected: selectedEmotion == emotion,
                                imageName: item?.imageName,
                                title: emotion.title,
                                tint: item?.color ?? .gray
                            ) {
                                withAnimation(.easeInOut) {
                                    selectedEmotion = emotion
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Button {
                        if recorder.isRecording {
                            stopRecordingAndMaybeSave(save: false)
                        }
                        isPresented = false
                    } label: {
                        Text("Cancelar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.colors.cardBackground)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if recorder.isRecording {
                            stopRecordingAndMaybeSave(save: true)
                        } else {
                            if let url = tempURL {
                                onFinish(url, recorder.currentTime, selectedEmotion)
                                tempURL = nil
                                isPresented = false
                            }
                        }
                    } label: {
                        Text(recorder.isRecording ? "Detener y guardar" : "Guardar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled || (tempURL == nil && !recorder.isRecording))
                    .opacity(isDisabled ? 0.6 : 1.0)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                Spacer()
            }
        }
        .onChange(of: recorder.currentTime) { _, newValue in
            if recorder.isRecording && newValue >= maxDuration {
                stopRecordingAndMaybeSave(save: true)
            }
        }
    }
    
    private func stopRecordingAndMaybeSave(save: Bool) {
        recorder.stopRecording()
        guard save else {
            if let url = tempURL {
                try? FileManager.default.removeItem(at: url)
                tempURL = nil
            }
            return
        }
        if let url = tempURL {
            let duration = recorder.currentTime
            onFinish(url, duration, selectedEmotion)
            tempURL = nil
            isPresented = false
        }
    }
    
    private func timeString(_ t: TimeInterval) -> String {
        let seconds = Int(t.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%01d:%02d", m, s)
    }
}

private struct EmotionChip: View {
    let isSelected: Bool
    let imageName: String?
    let title: String
    let tint: Color
    let action: () -> Void
    
    @Environment(\.themeManager) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(isSelected ? tint : .primary)
                }
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? tint : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
        isSelected ? AnyShapeStyle(tint.opacity(0.2)) : AnyShapeStyle(theme.colors.chipBackground)
    }
    private var border: Color {
        isSelected ? tint : theme.colors.separator
    }
}
