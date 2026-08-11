//
//  AppDelegate.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa
//

import Foundation
import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase SDK when the app launches
        FirebaseApp.configure()
        
        return true
    }
}
