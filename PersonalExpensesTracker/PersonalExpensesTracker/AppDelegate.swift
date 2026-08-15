//
//  AppDelegate.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 15/08/2026.
//

import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // 1. Initialize Firebase first before any UI setup
        FirebaseApp.configure()
        
        // 2. Configure Root View Controller based on Auth State
        setupRootViewController()
        
        return true
    }

    private func setupRootViewController() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "PersonalExpensesTracker", bundle: nil)
        
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            window.rootViewController = loginVC
        } else if let initialVC = storyboard.instantiateInitialViewController() {
            window.rootViewController = initialVC
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}
