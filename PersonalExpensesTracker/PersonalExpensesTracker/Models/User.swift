//
//  User.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import Foundation

struct User {
    let uid: String
    let email: String
    let username: String
    let preferredCurrency: String
    
    init(uid: String, email: String, username: String = "", preferredCurrency: String = "USD") {
        self.uid = uid
        self.email = email
        self.username = username
        self.preferredCurrency = preferredCurrency
    }
    
    // Convert Firestore Dictionary into User model
    init?(uid: String, dictionary: [String: Any])
    {
        guard let email = dictionary["email"] as? String else { return nil }
        self.uid = uid
        self.email = email
        self.username = dictionary["username"] as? String ?? ""
        self.preferredCurrency = dictionary["preferredCurrency"] as? String ?? "USD"
    }
    
    var dictionary: [String: Any] {
        return [
            "email": email,
            "username": username,
            "preferredCurrency": preferredCurrency
        ]
    }
}
