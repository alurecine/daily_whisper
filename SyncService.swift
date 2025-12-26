import Foundation
internal import CoreData

enum SyncServiceError: Error {
    case missingUserId
    case missingLocalFile
    case invalidImageData
    case unknown
}

final class SyncService {
    private let db: CloudDatabase
    private let storage: CloudStorage
    private let paths: CloudPathResolver
    
    init(db: CloudDatabase, storage: CloudStorage, paths: CloudPathResolver = DefaultPathResolver()) {
        self.db = db
        self.storage = storage
        self.paths = paths
    }
    
    // MARK: - User
    
    // Sube avatar y persiste URL en BD
    func uploadUserAvatarAndSave(user: User, imageData: Data) async throws -> UserDTO {
        let userId = (user.value(forKey: "id") as? UUID)?.uuidString
        guard let userId else { throw SyncServiceError.missingUserId }
        
        let avatarPath = paths.userAvatarPath(userId: userId)
        // Ajusta contentType según el formato real del Data
        let remoteURL = try await storage.upload(data: imageData, to: avatarPath, contentType: "image/jpeg")
        
        var dto = UserDTO.fromCoreData(user, imageURL: remoteURL.absoluteString)
        dto.updatedAt = Date()
        try await db.saveUser(dto)
        return dto
    }
    
    // Guarda el perfil del usuario en BD (sin tocar avatar)
    func saveUserProfile(user: User, profileImageURL: String? = nil) async throws -> UserDTO {
        let dto = UserDTO.fromCoreData(user, imageURL: profileImageURL)
        try await db.saveUser(dto)
        return dto
    }
    
    // Lee usuario remoto
    func fetchRemoteUser(userId: String) async throws -> UserDTO? {
        try await db.fetchUser(id: userId)
    }
    
    // MARK: - Audio
    
    // Sube audio local a Storage y guarda entrada en BD
    func uploadAudioAndSave(entry: AudioEntry, ownerUserId: String) async throws -> AudioEntryDTO {
        guard let storedPath = entry.value(forKey: "fileURL") as? String else {
            throw SyncServiceError.missingLocalFile
        }
        let localURL: URL
        if storedPath.hasPrefix("file://") {
            guard let url = URL(string: storedPath) else { throw SyncServiceError.missingLocalFile }
            localURL = url
        } else {
            localURL = URL(fileURLWithPath: storedPath)
        }
        
        let entryId = (entry.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
        let remotePath = paths.audioFilePath(userId: ownerUserId, entryId: entryId, fileExtension: "m4a")
        // AAC en contenedor m4a -> audio/mp4 suele ser correcto; ajusta si usas otro formato
        let remoteURL = try await storage.uploadFile(from: localURL, to: remotePath, contentType: "audio/mp4")
        
        var dto = AudioEntryDTO.fromCoreData(entry, userId: ownerUserId, remoteFileURL: remoteURL.absoluteString)
        dto.date = dto.date ?? Date()
        try await db.saveAudioEntry(dto)
        return dto
    }
    
    func saveAudioEntry(_ dto: AudioEntryDTO) async throws {
        try await db.saveAudioEntry(dto)
    }
    
    func fetchRemoteEntries(forUserId userId: String, limit: Int? = nil) async throws -> [AudioEntryDTO] {
        try await db.fetchAudioEntries(forUserId: userId, limit: limit)
    }
    
    // MARK: - Lotes
    
    // Sube todos los audios locales del usuario (útil primera sincronización)
    func uploadAllLocalAudios(forUserId userId: String, context: NSManagedObjectContext) async {
        let request: NSFetchRequest<AudioEntry> = AudioEntry.fetchRequest()
        do {
            let entries = try context.fetch(request)
            for entry in entries {
                do {
                    _ = try await uploadAudioAndSave(entry: entry, ownerUserId: userId)
                } catch {
                    print("Upload failed for entry \(entry): \(error)")
                }
            }
        } catch {
            print("Fetch local entries failed: \(error)")
        }
    }
}

