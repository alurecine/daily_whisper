//
//  UserRepository.swift
//  daily-whisper
//
//  Created by Alan Recine on 26/12/2025.
//

import Foundation
internal import CoreData

enum UserRepositoryError: Error {
    case entityNotFound
}

struct UserRepository {
    
    // Obtiene el único usuario; si no existe, lo crea con valores por defecto.
    static func fetchOrCreateUser(in context: NSManagedObjectContext) throws -> User {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        
        if let existing = try context.fetch(request).first {
            return existing
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "User", in: context) else {
            throw UserRepositoryError.entityNotFound
        }
        
        let user = User(entity: entity, insertInto: context)
        // Valores iniciales (usa las claves tal como están definidas en el .xcdatamodeld)
        user.setValue(UUID(), forKey: "id") // si no tienes "id" en el modelo, comenta esta línea.
        user.setValue("Tu nombre", forKey: "name")
        user.setValue("tu@email.com", forKey: "email")
        let now = Date()
        user.setValue(now, forKey: "createdAt") // si no tienes createdAt, comenta esta línea.
        user.setValue(now, forKey: "updatedAt") // si no tienes updatedAt, comenta esta línea.
        
        try context.save()
        return user
    }
    
    // Actualiza nombre y/o email
    static func update(in context: NSManagedObjectContext,
                       user: User,
                       name: String?,
                       email: String?) throws {
        user.setValue(name, forKey: "name")
        user.setValue(email, forKey: "email")
        user.setValue(Date(), forKey: "updatedAt") // comenta si no tienes updatedAt
        try context.save()
    }
    
    // Guarda imagen de perfil (Data)
    static func setProfileImage(in context: NSManagedObjectContext,
                                user: User,
                                imageData: Data?) throws {
        user.setValue(imageData, forKey: "profileImageData")
        user.setValue(Date(), forKey: "updatedAt") // comenta si no tienes updatedAt
        try context.save()
    }
    
    // Devuelve la imagen de perfil (Data)
    static func getProfileImage(user: User) -> Data? {
        user.value(forKey: "profileImageData") as? Data
    }
}

