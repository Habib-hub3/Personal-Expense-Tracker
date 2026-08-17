//
//  SharedSettingsStore.swift
//  PersonalExpensesTracker
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum SharedSettingsStore {
    static let settingsDidChangeNotification = Notification.Name("SharedSettingsStore.settingsDidChange")
    
    private static var listener: ListenerRegistration?
    
    static func startListeningForCurrentUser() {
        guard let email = Auth.auth().currentUser?.email else { return }
        startListening(email: email)
    }
    
    static func startListening(email: String) {
        listener?.remove()
        listener = settingsDocument(for: email).addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                apply(data)
            }
        }
    }
    
    static func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    static func save(_ values: [String: Any], completion: ((Error?) -> Void)? = nil) {
        guard let email = Auth.auth().currentUser?.email else {
            completion?(nil)
            return
        }
        
        var syncedValues = values
        syncedValues["settingsUpdatedAt"] = FieldValue.serverTimestamp()
        settingsDocument(for: email).setData(syncedValues, merge: true, completion: completion)
    }
    
    static func apply(_ data: [String: Any]) {
        if let isDarkMode = data["isDarkMode"] as? Bool {
            AppearanceManager.applyDarkMode(isDarkMode)
        }
        
        if let currency = nonEmpty(data["preferredCurrency"] as? String) ?? nonEmpty(data["currency"] as? String) {
            UserDefaults.standard.set(currency, forKey: "appCurrency")
        }
        
        if let category = nonEmpty(data["defaultCategory"] as? String) {
            UserDefaults.standard.set(category, forKey: "defaultCategory")
        }
        
        if let dailyReminders = data["dailyReminders"] as? Bool {
            UserDefaults.standard.set(dailyReminders, forKey: "dailyReminders")
        }
        
        if let reminderDate = reminderDate(from: data) {
            UserDefaults.standard.set(reminderDate, forKey: "reminderTime")
        }
        
        if let profileImageBase64 = nonEmpty(data["profileImageBase64"] as? String),
           let uid = Auth.auth().currentUser?.uid {
            UserDefaults.standard.set(profileImageBase64, forKey: "profileImageBase64_\(uid)")
        }
        
        NotificationCenter.default.post(name: settingsDidChangeNotification, object: nil, userInfo: data)
    }
    
    static func accountSettingsDocumentID(for email: String) -> String {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return Data(normalizedEmail.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private static func settingsDocument(for email: String) -> DocumentReference {
        Firestore.firestore()
            .collection("accountSettings")
            .document(accountSettingsDocumentID(for: email))
    }
    
    private static func reminderDate(from data: [String: Any]) -> Date? {
        guard let hour = data["reminderHour"] as? Int,
              let minute = data["reminderMinute"] as? Int else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }
    
    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
            return nil
        }
        return trimmedValue
    }
}
