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
                    .blur(radius: cfg.haloBlurRadius) // difuminado suave del halo
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: cfg.pulseDuration).repeatForever(autoreverses: true), value: breathe)
            }
            
            // Botón principal
            Circle()
                .fill(currentColor)
                .frame(width: cfg.size, height: cfg.size)
                .scaleEffect(currentScale)
                .shadow(color: currentShadowColor, radius: currentShadowRadius, x: 0, y: 4)
                .blur(radius: currentBlurRadius) // difuminar ligeramente cuando está grabando
                .opacity(currentOpacity) // una leve respiración de opacidad
                .animation(.easeInOut(duration: 0.2), value: recorder.isRecording) // transición rápida al iniciar/parar
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
        // Separación extra configurable para que no se pise con el timer de abajo
        .padding(.bottom, cfg.bottomPadding)
        .onChange(of: recorder.isRecording) { _, newValue in
            if newValue {
                startBreathing()
            } else {
                stopBreathing()
            }
        }
    }
    
    // Color actual
    private var currentColor: Color {
        recorder.isRecording ? cfg.recordingColor : cfg.idleColor
    }
    
    // Escala del botón según estado
    private var currentScale: CGFloat {
        if recorder.isRecording {
            return breathe ? cfg.pulseScale : cfg.baseScale
        } else {
            return cfg.baseScale
        }
    }
    
    // Escala del halo según estado de respiración
    private var haloScale: CGFloat {
        breathe ? cfg.haloMaxScale : cfg.haloMinScale
    }
    
    // Opacidad del halo según estado de respiración
    private var haloOpacity: Double {
        breathe ? cfg.haloMaxOpacity : cfg.haloMinOpacity
    }
    
    // Difuminado y sombra cuando está grabando (para que se vea menos estático)
    private var currentBlurRadius: CGFloat {
        recorder.isRecording ? cfg.recordingBlurRadius : 0
    }
    
    private var currentShadowRadius: CGFloat {
        recorder.isRecording ? cfg.recordingShadowRadius : cfg.idleShadowRadius
    }
    
    private var currentShadowColor: Color {
        recorder.isRecording ? cfg.recordingShadowColor : cfg.idleShadowColor
    }
    
    // Pequeña respiración de opacidad para que no sea plano
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
        // Reinicia el estado y lanza animación cíclica
        breathe = false
        withAnimation(.easeInOut(duration: cfg.pulseDuration).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
    
    private func stopBreathing() {
        // Detener el pulso y volver a estado base
        breathe = false
    }
}

