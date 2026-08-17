//
//  AppearanceManager.swift
//  PersonalExpensesTracker
//

import UIKit

enum AppearanceManager {
    static let darkModeDefaultsKey = "isDarkMode"
    
    static var savedStyle: UIUserInterfaceStyle {
        UserDefaults.standard.bool(forKey: darkModeDefaultsKey) ? .dark : .light
    }
    
    static func applySavedAppearance() {
        apply(style: savedStyle)
    }
    
    static func applyDarkMode(_ isDarkMode: Bool) {
        UserDefaults.standard.set(isDarkMode, forKey: darkModeDefaultsKey)
        apply(style: isDarkMode ? .dark : .light)
    }
    
    static func applyLightMode() {
        apply(style: .light)
    }
    
    private static func apply(style: UIUserInterfaceStyle) {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}
