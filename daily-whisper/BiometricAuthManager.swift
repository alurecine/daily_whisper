//
//  BiometricAuthManager.swift
//  daily-whisper
//
//  Created by Alan Recine on 23/12/2025.
//

import Foundation
import LocalAuthentication

enum BiometricAuthResult {
    case success
    case failure
    case notAvailable
}

final class BiometricAuthManager {
    
    // Intenta SOLO biometría primero (Face ID/Touch ID). No cae a passcode automáticamente.
    func authenticateBiometricsFirst(reason: String) async -> BiometricAuthResult {
        let context = LAContext()
        context.localizedFallbackTitle = "" // ocultar botón "Usar código" en este paso
        var error: NSError?
        
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        guard context.canEvaluatePolicy(policy, error: &error) else {
            return .notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            return success ? .success : .failure
        } catch {
            return .failure
        }
    }
    
    // Fallback: permite biometría o passcode (según decida el sistema).
    func authenticateWithPasscode(reason: String) async -> BiometricAuthResult {
        let context = LAContext()
        context.localizedFallbackTitle = "Usar código"
        var error: NSError?
        
        let policy: LAPolicy = .deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &error) else {
            return .notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            return success ? .success : .failure
        } catch {
            return .failure
        }
    }
}

