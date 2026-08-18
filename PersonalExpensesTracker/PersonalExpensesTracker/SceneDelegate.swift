//
//  SceneDelegate.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let storyboard = UIStoryboard(name: "PersonalExpensesTracker", bundle: nil)
        let rootViewController: UIViewController
        
        let isLoggedIn = Auth.auth().currentUser != nil && UserDefaults.standard.bool(forKey: "isLoggedIn")
        if isLoggedIn,
           let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            tabBarController.selectedIndex = 0
            rootViewController = tabBarController
        } else {
            rootViewController = storyboard.instantiateInitialViewController() ?? UIViewController()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.overrideUserInterfaceStyle = AppearanceManager.savedStyle
        self.window = window
        window.makeKeyAndVisible()
        
        if isLoggedIn, let email = Auth.auth().currentUser?.email {
            loadSharedSettings(email: email, window: window)
            SharedSettingsStore.startListening(email: email)
        }
    }
    
    private func loadSharedSettings(email: String, window: UIWindow) {
        Firestore.firestore()
            .collection("accountSettings")
            .document(accountSettingsDocumentID(for: email))
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                DispatchQueue.main.async {
                    SharedSettingsStore.apply(data)
                }
            }
    }
    
    private func accountSettingsDocumentID(for email: String) -> String {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return Data(normalizedEmail.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}
