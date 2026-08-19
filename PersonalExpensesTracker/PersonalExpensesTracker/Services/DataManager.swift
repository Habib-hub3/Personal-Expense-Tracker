//
//  DataManager.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class DataManager {
    // MARK: - Singleton
    
    static let shared = DataManager()
    
    // MARK: - Dependencies
    
    private let db = Firestore.firestore()
    private let dataError = NSError(
        domain: "PersonalExpensesTracker.DataManager",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to load the requested data."]
    )
    
    private init() {}
    
    // MARK: - Authentication
    
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - User Profiles
    
    func saveUserProfile(user: User, completion: @escaping (Bool) -> Void)
    {
        var profileData = user.dictionary
        profileData["normalizedUsername"] = Self.normalizedUsername(user.username)
        db.collection("users").document(user.uid).setData(profileData, merge: true) { error in
            completion(error == nil)
        }
    }
    
    func isUsernameAvailable(_ username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let normalizedUsername = Self.normalizedUsername(username)
        guard !normalizedUsername.isEmpty else {
            completion(.success(false))
            return
        }
        
        db.collection("usernames").document(normalizedUsername).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(snapshot?.exists != true))
            }
        }
    }
    
    func reserveUsername(_ username: String, uid: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let normalizedUsername = Self.normalizedUsername(username)
        guard !normalizedUsername.isEmpty else {
            completion(.failure(usernameError("Please enter a valid username.")))
            return
        }
        
        let usernameReference = db.collection("usernames").document(normalizedUsername)
        db.runTransaction({ transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(usernameReference)
                if snapshot.exists {
                    errorPointer?.pointee = self.usernameError("Username already taken.")
                    return nil
                }
                
                transaction.setData([
                    "uid": uid,
                    "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                    "username": username,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: usernameReference)
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchUserProfile(completion: @escaping (Result<User, Error>) -> Void) {
        guard let uid = currentUserID else {
            completion(.failure(dataError))
            return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let fallbackUser = self.authFallbackUser(uid: uid)
            let currentProfile: User
            if let snapshot = snapshot,
               snapshot.exists,
               let data = snapshot.data(),
               let user = User(uid: uid, dictionary: data) {
                currentProfile = self.mergedProfile(uid: uid, current: fallbackUser, candidate: user)
            } else {
                currentProfile = fallbackUser
            }
            
            guard let email = self.nonEmpty(currentProfile.email), self.isSparseProfile(currentProfile, email: email) else {
                if snapshot?.exists != true {
                    self.saveUserProfile(user: currentProfile) { _ in }
                }
                completion(.success(currentProfile))
                return
            }
            
            self.fetchRicherProfileForEmail(uid: uid, email: email, currentProfile: currentProfile) { repairedProfile in
                if self.profileScore(repairedProfile, email: email) > self.profileScore(currentProfile, email: email) || snapshot?.exists != true {
                    self.saveUserProfile(user: repairedProfile) { _ in }
                }
                completion(.success(repairedProfile))
            }
        }
    }
    
    // MARK: - Profile Repair
    
    private func authFallbackUser(uid: String) -> User {
        let authUser = Auth.auth().currentUser
        let email = authUser?.email ?? ""
        let displayName = authUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nameParts = displayName.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")
        let username = displayName.isEmpty ? email.components(separatedBy: "@").first ?? "" : displayName
        let fallbackFirstName = firstName.isEmpty ? username : firstName
        
        return User(
            uid: uid,
            email: email,
            username: username,
            firstName: fallbackFirstName,
            lastName: lastName
        )
    }
    
    private func fetchRicherProfileForEmail(
        uid: String,
        email: String,
        currentProfile: User,
        completion: @escaping (User) -> Void
    ) {
        fetchProfilesByEmailQueries(email: email) { queriedProfiles in
            if let bestProfile = self.bestRicherProfile(from: queriedProfiles, email: email, currentProfile: currentProfile) {
                completion(self.mergedProfile(uid: uid, current: currentProfile, candidate: bestProfile))
                return
            }
            
            self.fetchProfilesByScanningUsers(email: email) { scannedProfiles in
                guard let bestProfile = self.bestRicherProfile(from: scannedProfiles, email: email, currentProfile: currentProfile) else {
                    completion(currentProfile)
                    return
                }
                
                completion(self.mergedProfile(uid: uid, current: currentProfile, candidate: bestProfile))
            }
        }
    }
    
    // Searches both modern and legacy email fields before falling back to a limited scan.
    private func fetchProfilesByEmailQueries(email: String, completion: @escaping ([User]) -> Void) {
        let emailValues = Array(Set([email, email.lowercased()]))
        let fields = ["email", "userEmail"]
        let group = DispatchGroup()
        var profilesByID: [String: User] = [:]
        
        for field in fields {
            for emailValue in emailValues {
                group.enter()
                db.collection("users").whereField(field, isEqualTo: emailValue).getDocuments { snapshot, _ in
                    snapshot?.documents.forEach { document in
                        guard self.documentEmailMatches(document.data(), email: email),
                              let user = User(uid: document.documentID, dictionary: document.data()) else { return }
                        profilesByID[document.documentID] = user
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(Array(profilesByID.values))
        }
    }
    
    private func fetchProfilesByScanningUsers(email: String, completion: @escaping ([User]) -> Void) {
        db.collection("users").limit(to: 100).getDocuments { snapshot, _ in
            let profiles = snapshot?.documents.compactMap { document -> User? in
                guard self.documentEmailMatches(document.data(), email: email) else { return nil }
                return User(uid: document.documentID, dictionary: document.data())
            } ?? []
            completion(profiles)
        }
    }
    
    // MARK: - Profile Helpers
    
    private func bestRicherProfile(from profiles: [User], email: String, currentProfile: User) -> User? {
        guard let bestProfile = profiles.max(by: {
            self.profileScore($0, email: email) < self.profileScore($1, email: email)
        }),
              profileScore(bestProfile, email: email) > profileScore(currentProfile, email: email) else {
            return nil
        }
        
        return bestProfile
    }
    
    private func mergedProfile(uid: String, current: User, candidate: User) -> User {
        let email = nonEmpty(current.email) ?? nonEmpty(candidate.email) ?? Auth.auth().currentUser?.email ?? ""
        return User(
            uid: uid,
            email: email,
            username: preferredName(current: current.username, candidate: candidate.username, email: email),
            firstName: preferredName(current: current.firstName, candidate: candidate.firstName, email: email),
            lastName: nonEmpty(current.lastName) ?? nonEmpty(candidate.lastName) ?? "",
            profileImageBase64: current.profileImageBase64 ?? candidate.profileImageBase64,
            preferredCurrency: current.preferredCurrency.isEmpty ? candidate.preferredCurrency : current.preferredCurrency
        )
    }
    
    private func preferredName(current: String, candidate: String, email: String) -> String {
        let emailUsername = usernameFromEmail(email)
        if let candidate = nonEmpty(candidate), candidate.caseInsensitiveCompare(emailUsername) != .orderedSame {
            return candidate
        }
        if let current = nonEmpty(current) {
            return current
        }
        return nonEmpty(candidate) ?? ""
    }
    
    private func isSparseProfile(_ user: User, email: String) -> Bool {
        let emailUsername = usernameFromEmail(email)
        let weakUsername = user.username.isEmpty || user.username.caseInsensitiveCompare(emailUsername) == .orderedSame
        let weakFirstName = user.firstName.isEmpty || user.firstName.caseInsensitiveCompare(emailUsername) == .orderedSame
        return user.lastName.isEmpty && (weakUsername || weakFirstName)
    }
    
    private func profileScore(_ user: User, email: String) -> Int {
        let emailUsername = usernameFromEmail(email)
        var score = 0
        
        if !user.username.isEmpty {
            score += user.username.caseInsensitiveCompare(emailUsername) == .orderedSame ? 1 : 4
        }
        if !user.firstName.isEmpty {
            score += user.firstName.caseInsensitiveCompare(emailUsername) == .orderedSame ? 1 : 4
        }
        if !user.lastName.isEmpty {
            score += 4
        }
        if !user.fullName.isEmpty && user.fullName.caseInsensitiveCompare(emailUsername) != .orderedSame {
            score += 2
        }
        if user.profileImageBase64 != nil {
            score += 1
        }
        
        return score
    }
    
    private func usernameFromEmail(_ email: String) -> String {
        email.components(separatedBy: "@").first ?? ""
    }
    
    private func documentEmailMatches(_ data: [String: Any], email: String) -> Bool {
        let normalizedEmail = email.lowercased()
        let emailKeys = ["email", "userEmail", "Email"]
        return emailKeys.contains { key in
            guard let value = data[key] as? String else { return false }
            return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedEmail
        }
    }
    
    // MARK: - Username Helpers
    
    static func normalizedUsername(_ username: String) -> String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
    private func usernameError(_ message: String) -> NSError {
        NSError(
            domain: "PersonalExpensesTracker.Username",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
            return nil
        }
        return trimmedValue
    }
    
    // MARK: - Expense Operations
    
    func addExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        ExpenseStore.addExpense(expense.dictionary) { error in
            completion(error == nil)
        }
    }
    
    func fetchExpenses(completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let expensesCollection = ExpenseStore.currentExpensesCollection else {
            completion(.failure(dataError))
            return
        }
        
        ExpenseStore.migrateLegacyExpensesIfNeeded {
            expensesCollection
                .order(by: "date", descending: true)
                .getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.failure(self.dataError))
                return
            }
                
                let expenses = documents.compactMap {
                    doc -> Expense? in
                    return Expense(id: doc.documentID, dictionary: doc.data())
                }
                completion(.success(expenses))
            }
        }
    }
    
    func updateExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        ExpenseStore.updateExpense(id: expense.id, data: expense.dictionary) { error in
            completion(error == nil)
        }
    }
    
    func deleteExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        ExpenseStore.deleteExpenseEverywhere(id: expense.id) { error in
            completion(error == nil)
        }
    }
}
