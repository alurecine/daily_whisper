import Foundation
internal import CoreData

struct AudioEntryDTO: Codable, Identifiable, Equatable {
    var id: String
    var date: Date?
    var fileURL: String // URL remota (Storage) o path local provisional
    var duration: Double
    var emotion: String?
    var userId: String?
}

extension AudioEntryDTO {
    static func fromCoreData(_ entry: AudioEntry,
                             userId: String? = nil,
                             remoteFileURL: String? = nil) -> AudioEntryDTO {
        let id = (entry.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
        let localPath = entry.value(forKey: "fileURL") as? String ?? ""
        return AudioEntryDTO(
            id: id,
            date: entry.value(forKey: "date") as? Date,
            fileURL: remoteFileURL ?? localPath,
            duration: entry.value(forKey: "duration") as? Double ?? 0,
            emotion: entry.value(forKey: "emotion") as? String,
            userId: userId
        )
    }
}

