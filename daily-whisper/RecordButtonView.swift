//
//  RecordButtonView.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import SwiftUI

struct RecordButtonView: View {
    
    @ObservedObject var recorder: AudioRecorderManager
    let onFinish: (URL, Double) -> Void
    
    @State private var fileURL: URL?
    @State private var isPressing = false
    
    // Animación de “respiración”
    @State private var breathe = false
    
    // Acceso rápido a la config
    private var cfg: AppConfig.UI.RecordButton { AppConfig.shared.ui.recordButton }
    
    var body: some View {
        ZStack {
            // HALO respirando (solo visible grabando)
            if recorder.isRecording {
                Circle()
                    .fill(currentColor)
                    .frame(width: cfg.size, height: cfg.size)
                    .scaleEffect(haloScale)
                    .opacity(haloOpacity)
                    .blur(radius: cfg.haloBlurRadius)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: cfg.pulseDuration).repeatForever(autoreverses: true), value: breathe)
            }
            
            // Botón principal (idle difuminado, recording conserva estilo actual)
            Circle()
                .fill(currentColor.opacity(recorder.isRecording ? 1.0 : cfg.idleOpacity))
                .frame(width: cfg.size, height: cfg.size)
                .scaleEffect(currentScale)
                .shadow(color: currentShadowColor, radius: currentShadowRadius, x: 0, y: 4)
                .blur(radius: recorder.isRecording ? cfg.recordingBlurRadius : cfg.idleBlurRadius)
                .overlay {
                    if cfg.idleMaterialOverlay && !recorder.isRecording {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
                }
                .opacity(currentOpacity)
                .animation(.easeInOut(duration: 0.2), value: recorder.isRecording)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressing {
                                isPressing = true
                                start()
                            }
                        }
                        .onEnded { _ in
                            isPressing = false
                            stop()
                        }
                )
        }
        .padding(.bottom, cfg.bottomPadding)
        .onChange(of: recorder.isRecording) { _, newValue in
            if newValue {
                startBreathing()
            } else {
                stopBreathing()
            }
        }
    }
    
    private var currentColor: Color {
        recorder.isRecording ? cfg.recordingColor : cfg.idleColor
    }
    
    private var currentScale: CGFloat {
        if recorder.isRecording {
            return breathe ? cfg.pulseScale : cfg.baseScale
        } else {
            return cfg.baseScale
        }
    }
    
    private var haloScale: CGFloat {
        breathe ? cfg.haloMaxScale : cfg.haloMinScale
    }
    
    private var haloOpacity: Double {
        breathe ? cfg.haloMaxOpacity : cfg.haloMinOpacity
    }
    
    private var currentShadowRadius: CGFloat {
        recorder.isRecording ? cfg.recordingShadowRadius : cfg.idleShadowRadius
    }
    
    private var currentShadowColor: Color {
        recorder.isRecording ? cfg.recordingShadowColor : cfg.idleShadowColor
    }
    
    private var currentOpacity: Double {
        guard recorder.isRecording else { return 1.0 }
        return breathe ? cfg.recordingOpacityLow : 1.0
    }
    
    private func start() {
        do {
            fileURL = try recorder.startRecording()
        } catch {
            print("Error starting recording:", error)
        }
    }
    
    private func stop() {
        recorder.stopRecording()
        if let url = fileURL {
            onFinish(url, recorder.currentTime)
        }
    }
    
    private func startBreathing() {
        breathe = false
        withAnimation(.easeInOut(duration: cfg.pulseDuration).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
    
    private func stopBreathing() {
        breathe = false
    }
}
