import Foundation

// Base de datos (Firestore, por ejemplo)
protocol CloudDatabase {
    // Users
    func saveUser(_ user: UserDTO) async throws
    func fetchUser(id: String) async throws -> UserDTO?
    
    // Audio entries
    func saveAudioEntry(_ entry: AudioEntryDTO) async throws
    func fetchAudioEntries(forUserId userId: String, limit: Int?) async throws -> [AudioEntryDTO]
}

// Almacenamiento de ficheros (Firebase Storage, por ejemplo)
protocol CloudStorage {
    // Sube bytes y devuelve URL remota
    func upload(data: Data, to path: String, contentType: String) async throws -> URL
    // Sube archivo local y devuelve URL remota
    func uploadFile(from localURL: URL, to path: String, contentType: String) async throws -> URL
}

// Resolver de rutas remotas
protocol CloudPathResolver {
    func userAvatarPath(userId: String) -> String
    func audioFilePath(userId: String, entryId: String, fileExtension: String) -> String
}

