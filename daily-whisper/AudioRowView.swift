//
//  AudioRowView.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import Foundation
import SwiftUI

import SwiftUI

struct AudioRowView: View {
    let entry: AudioEntry
    @ObservedObject var player: AudioPlayerManager
    
    var isPlaying: Bool {
        player.currentEntryID == entry.id && player.isPlaying
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            Button {
                player.toggle(entry: entry)
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(formattedDate(entry.date ?? Date()))
                    .font(.body)
                
                Text("\(Int(entry.duration)) segundos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

