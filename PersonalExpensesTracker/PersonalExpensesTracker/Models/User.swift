//
//  User.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import Foundation

struct User {
    // MARK: - Properties
    
    let uid: String
    let email: String
    let username: String
    let firstName: String
    let lastName: String
    let profileImageBase64: String?
    let preferredCurrency: String
    
    // MARK: - Initialization
    
    init(
        uid: String,
        email: String,
        username: String = "",
        firstName: String = "",
        lastName: String = "",
        profileImageBase64: String? = nil,
        preferredCurrency: String = "USD"
    ) {
        self.uid = uid
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageBase64 = profileImageBase64
        self.preferredCurrency = preferredCurrency
    }
    
    // MARK: - Display Values
    
    var fullName: String {
        [firstName, lastName]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }
    
    // Accepts several legacy field names so older Firestore profiles still load correctly.
    init?(uid: String, dictionary: [String: Any])
    {
        self.uid = uid
        self.email = Self.stringValue(for: ["email", "userEmail"], in: dictionary)
        let fullName = Self.stringValue(for: ["fullName", "fullname", "full_name", "displayName", "name"], in: dictionary)
        let fullNameParts = Self.nameParts(from: fullName)
        self.username = Self.stringValue(for: ["username", "userName"], in: dictionary, defaultValue: fullName)
        self.firstName = Self.stringValue(for: ["firstName", "firstname", "first_name", "first", "First Name"], in: dictionary, defaultValue: fullNameParts.firstName)
        self.lastName = Self.stringValue(for: ["lastName", "lastname", "last_name", "last", "Last Name"], in: dictionary, defaultValue: fullNameParts.lastName)
        self.profileImageBase64 = Self.stringValue(for: ["profileImageBase64", "profileImage", "photoBase64"], in: dictionary)
        self.preferredCurrency = Self.stringValue(for: ["preferredCurrency", "currency"], in: dictionary, defaultValue: "USD")
    }
    
    // MARK: - Firestore Mapping
    
    var dictionary: [String: Any] {
        var data: [String: Any] = [
            "email": email,
            "username": username,
            "firstName": firstName,
            "lastName": lastName,
            "preferredCurrency": preferredCurrency
        ]
        
        if let profileImageBase64 = profileImageBase64 {
            data["profileImageBase64"] = profileImageBase64
        }
        
        return data
    }
    
    // MARK: - Parsing Helpers
    
    private static func stringValue(for keys: [String], in dictionary: [String: Any], defaultValue: String = "") -> String {
        for key in keys {
            if let value = dictionary[key] as? String {
                let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedValue.isEmpty {
                    return trimmedValue
                }
            }
        }
        return defaultValue
    }
    
    private static func nameParts(from fullName: String) -> (firstName: String, lastName: String) {
        let parts = fullName
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        guard let firstName = parts.first else { return ("", "") }
        return (firstName, parts.dropFirst().joined(separator: " "))
    }
}
