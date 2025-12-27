import Foundation
import StoreKit

enum AppProductID: String, CaseIterable {
    // Rellena con tus IDs reales de App Store Connect
    case proMonthly = "com.tuapp.pro.monthly"
    case proYearly  = "com.tuapp.pro.yearly"
    case unlimited  = "com.tuapp.unlimited.yearly"
    
    // Mapea cada producto a un rol de tu app
    var mappedRole: AppConfig.UserRole {
        switch self {
        case .proMonthly, .proYearly:
            return .pro
        case .unlimited:
            return .unlimited
        }
    }
}

struct ProductInfo: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let price: String
    let product: Product
}

enum PurchaseError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Producto no encontrado."
        case .userCancelled:   return "Compra cancelada por el usuario."
        case .purchasePending: return "La compra está pendiente."
        case .verificationFailed: return "No se pudo verificar la transacción."
        case .unknown:         return "Error desconocido."
        }
    }
}
