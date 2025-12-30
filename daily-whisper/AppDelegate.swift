//
//  AppDelegate.swift
//  daily-whisper
//
//  Created by Alan Recine on 30/12/2025.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Esto es clave: sin esto, el token FCM no va a recibir push vía APNs.
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM token:", fcmToken ?? "nil")
        // Acá normalmente lo guardarías en tu backend si vas a enviar a usuarios específicos.
    }
}
