//
//  SceneDelegate.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth

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
        
        if Auth.auth().currentUser != nil,
           let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            tabBarController.selectedIndex = 0
            rootViewController = tabBarController
        } else {
            rootViewController = storyboard.instantiateInitialViewController() ?? UIViewController()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        self.window = window
        window.makeKeyAndVisible()
    }
}
