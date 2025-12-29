//
//  IntegratedRecordingOverlay.swift
//  daily-whisper
//
//  Created by Alan Recine on 26/12/2025.
//

import SwiftUI

struct IntegratedRecordingOverlay: View {
    @Binding var isPresented: Bool
    let isDisabled: Bool
    @ObservedObject var recorder: AudioRecorderManager
    let onFinish: (URL, Double, AppConfig.Emotion) -> Void
    
    // Estado interno
    @State private var tempURL: URL?
    @State private var selectedEmotion: AppConfig.Emotion = .angelical
    
    // Estilo centralizado
    private var accent: Color { AppConfig.shared.ui.accentColor }
    private var maxDuration: TimeInterval { AppConfig.shared.audio.maxRecordingDuration }
    private var emotionOrder: [AppConfig.Emotion] { AppConfig.shared.ui.emotionOrder }
    private var emotionMap: [AppConfig.Emotion: AppConfig.UI.EmotionItem] { AppConfig.shared.ui.emotions }
    
    var body: some View {
        ZStack {
            // Fondo desenfocado
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tocar fuera cierra si no está grabando
                    if !recorder.isRecording {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 16) {
                // Barra superior con cerrar
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
                
                // Temporizador
                Text(timeString(recorder.currentTime) + " / " + timeString(maxDuration))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                // Botón de grabación reutilizando tu componente
                RecordButtonView(recorder: recorder) { url, duration in
                    tempURL = url
                    // No finalizamos aquí: dejamos que el usuario confirme con emoción seleccionada
                }
                .allowsHitTesting(!isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
                
                // Picker de emoción en chips
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
                
                // Botones de acción
                HStack(spacing: 12) {
                    Button {
                        // Cancelar
                        if recorder.isRecording {
                            stopRecordingAndMaybeSave(save: false)
                        }
                        isPresented = false
                    } label: {
                        Text("Cancelar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if recorder.isRecording {
                            // Si aún está grabando, detener y guardar
                            stopRecordingAndMaybeSave(save: true)
                        } else {
                            // Ya detenido: si tenemos URL, guardar
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
            // Si alcanzó el máximo, detener automáticamente
            if recorder.isRecording && newValue >= maxDuration {
                stopRecordingAndMaybeSave(save: true)
            }
        }
    }
    
    private func stopRecordingAndMaybeSave(save: Bool) {
        recorder.stopRecording()
        guard save else {
            // Si no guardamos, limpiar archivo temporal si existe
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

// Chip reutilizable para el picker de emoción dentro del overlay
private struct EmotionChip: View {
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
        isSelected ? AnyShapeStyle(tint.opacity(0.2)) : AnyShapeStyle(Color(.secondarySystemBackground))
    }
    private var border: Color {
        isSelected ? tint : Color.black.opacity(0.08)
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        IntegratedRecordingOverlay(
            isPresented: .constant(true),
            isDisabled: false,
            recorder: AudioRecorderManager()
        ) { _, _, _ in }
    }
}
