import Foundation

struct DefaultPathResolver: CloudPathResolver {
    func userAvatarPath(userId: String) -> String {
        // Puedes cambiar a .png según lo que generes desde PhotosPicker
        "users/\(userId)/avatar.jpg"
    }
    func audioFilePath(userId: String, entryId: String, fileExtension: String) -> String {
        "users/\(userId)/audio/\(entryId).\(fileExtension.lowercased())"
    }
}

