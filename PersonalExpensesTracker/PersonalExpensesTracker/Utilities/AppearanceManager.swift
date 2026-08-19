//
//  AppearanceManager.swift
//  PersonalExpensesTracker
//

import UIKit

enum AppearanceManager {
    // MARK: - Defaults
    
    static let darkModeDefaultsKey = "isDarkMode"
    
    static var savedStyle: UIUserInterfaceStyle {
        UserDefaults.standard.bool(forKey: darkModeDefaultsKey) ? .dark : .light
    }
    
    // MARK: - Applying Appearance
    
    static func applySavedAppearance() {
        if UserDefaults.standard.object(forKey: darkModeDefaultsKey) == nil {
            apply(style: .unspecified)
        } else {
            apply(style: savedStyle)
        }
    }
    
    static func applyDarkMode(_ isDarkMode: Bool) {
        UserDefaults.standard.set(isDarkMode, forKey: darkModeDefaultsKey)
        apply(style: isDarkMode ? .dark : .light)
    }
    
    static func applyLightMode() {
        apply(style: .light)
    }
    
    static func applySystemDefault() {
        UserDefaults.standard.removeObject(forKey: darkModeDefaultsKey)
        apply(style: .unspecified)
    }
    
    // MARK: - Window Updates
    
    private static func apply(style: UIUserInterfaceStyle) {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}
