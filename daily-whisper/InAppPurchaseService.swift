import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
final class InAppPurchaseService: ObservableObject {
    @Published private(set) var products: [ProductInfo] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var lastErrorMessage: String?
    
    @AppStorage("user.role") private var storedUserRoleRaw: String = AppConfig.UserRole.normal.rawValue
    
    private let productIDs: [String]
    
    init(productIDs: [AppProductID] = [.proMonthly, .proYearly, .unlimited]) {
        self.productIDs = productIDs.map { $0.rawValue }
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let storeProducts = try await Product.products(for: productIDs)
            let infos: [ProductInfo] = storeProducts.map { product in
                ProductInfo(
                    id: product.id,
                    displayName: product.displayName,
                    description: product.description,
                    price: product.displayPrice,
                    product: product
                )
            }
            self.products = infos
        } catch {
            lastErrorMessage = "No se pudieron cargar productos: \(error)"
            ToastCenter.shared.error("Error cargando productos", message: error.localizedDescription)
        }
    }
    
    func purchase(productID: AppProductID) async -> Result<Void, PurchaseError> {
        do {
            let product: Product
            if let info = products.first(where: { $0.id == productID.rawValue }) {
                product = info.product
            } else {
                let prods = try await Product.products(for: [productID.rawValue])
                guard let first = prods.first else { return .failure(.productNotFound) }
                product = first
            }
            let res = await purchaseProduct(product, mappedRole: productID.mappedRole)
            if case .success = res {
                ToastCenter.shared.success("Suscripción activa", message: "Gracias por tu compra")
            } else if case .failure(let err) = res, err != .userCancelled {
                ToastCenter.shared.error("Compra fallida", message: err.localizedDescription)
            }
            return res
        } catch {
            ToastCenter.shared.error("Compra fallida", message: error.localizedDescription)
            return .failure(.unknown)
        }
    }
    
    private func purchaseProduct(_ product: Product, mappedRole: AppConfig.UserRole) async -> Result<Void, PurchaseError> {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard let transaction = try? checkVerified(verification) else {
                    return .failure(.verificationFailed)
                }
                applyRole(mappedRole)
                await transaction.finish()
                return .success(())
            case .userCancelled:
                return .failure(.userCancelled)
            case .pending:
                return .failure(.purchasePending)
            @unknown default:
                return .failure(.unknown)
            }
        } catch {
            return .failure(.unknown)
        }
    }
    
    func restorePurchases() async {
        var restored = false
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let role = mapProductToRole(transaction.productID) {
                    applyRole(role)
                    restored = true
                }
            } catch {
                // ignore
            }
        }
        if restored {
            ToastCenter.shared.info("Compras restauradas")
        } else {
            ToastCenter.shared.warning("Nada para restaurar")
        }
    }
    
    func startListeningForTransactions() {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }
    
    @MainActor
    private func handleTransactionUpdate(_ result: StoreKit.VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            if let role = mapProductToRole(transaction.productID) {
                applyRole(role)
                ToastCenter.shared.success("Suscripción actualizada")
            }
            await transaction.finish()
        } catch {
            // ignore
        }
    }
    
    private func mapProductToRole(_ productID: String) -> AppConfig.UserRole? {
        guard let appID = AppProductID(rawValue: productID) else { return nil }
        return appID.mappedRole
    }
    
    private func applyRole(_ role: AppConfig.UserRole) {
        AppConfig.shared.subscription.role = role
        storedUserRoleRaw = role.rawValue
    }
    
    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
