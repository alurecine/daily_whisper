import Foundation
internal import CoreData

struct UserDTO: Codable, Identifiable, Equatable {
    var id: String
    var name: String?
    var email: String?
    var createdAt: Date?
    var updatedAt: Date?
    // URL remota en Storage (no guardes Data cruda en Firestore)
    var profileImageURL: String?
    
    init(id: String,
         name: String? = nil,
         email: String? = nil,
         createdAt: Date? = nil,
         updatedAt: Date? = nil,
         profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageURL = profileImageURL
    }
}

extension UserDTO {
    static func fromCoreData(_ user: User, imageURL: String? = nil) -> UserDTO {
        let id = (user.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
        return UserDTO(
            id: id,
            name: user.value(forKey: "name") as? String,
            email: user.value(forKey: "email") as? String,
            createdAt: user.value(forKey: "createdAt") as? Date,
            updatedAt: user.value(forKey: "updatedAt") as? Date,
            profileImageURL: imageURL
        )
    }
}

