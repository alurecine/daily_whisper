// IconGenerator.swift (archivo nuevo opcional, solo para generar recursos)
import SwiftUI

struct AppIconView: View {
    let bg: Color = .blue
    var body: some View {
        ZStack {
            bg
            Image(systemName: "mic.fill")
                .resizable()
                .scaledToFit()
                .padding(180) // ajusta grosor del símbolo
                .foregroundColor(.white)
            // opcional: un pequeño brillo
            // Circle().stroke(Color.white.opacity(0.12), lineWidth: 8)
        }
        .frame(width: 1024, height: 1024)
        .clipped()
    }
}

@MainActor
func exportAppIconPNG() {
    let view = AppIconView()
    let renderer = ImageRenderer(content: view)
    // iOS 16+: usar uiImage y convertir a PNG
    #if canImport(UIKit)
    if let uiImage = renderer.uiImage,
       let data = uiImage.pngData() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-1024.png")
        do {
            try data.write(to: url)
            print("✅ App Icon exportado en:", url.path)
        } catch {
            print("❌ Error al escribir PNG:", error)
        }
    } else {
        print("❌ No se pudo renderizar la imagen del icono.")
    }
    #elseif canImport(AppKit)
    if let nsImage = renderer.nsImage {
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            print("❌ No se pudo convertir a PNG.")
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-1024.png")
        do {
            try data.write(to: url)
            print("✅ App Icon exportado en:", url.path)
        } catch {
            print("❌ Error al escribir PNG:", error)
        }
    } else {
        print("❌ No se pudo renderizar la imagen del icono.")
    }
    #endif
}
