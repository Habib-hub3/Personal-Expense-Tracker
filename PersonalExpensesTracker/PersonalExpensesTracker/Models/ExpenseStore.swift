//
//  ExpenseStore.swift
//  PersonalExpensesTracker
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum ExpenseStore {
    enum StoreError: LocalizedError {
        case notAuthenticated
        
        var errorDescription: String? {
            "User not authenticated."
        }
    }
    
    static var currentExpensesCollection: CollectionReference? {
        guard let ownerID = currentOwnerDocumentID else { return nil }
        return Firestore.firestore()
            .collection("accountExpenses")
            .document(ownerID)
            .collection("expenses")
    }
    
    static var legacyExpensesCollection: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("expenses")
    }
    
    static var currentOwnerEmail: String? {
        Auth.auth().currentUser?.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    static func migrateLegacyExpensesIfNeeded(completion: (() -> Void)? = nil) {
        guard currentOwnerEmail != nil,
              let currentCollection = currentExpensesCollection,
              let legacyCollection = legacyExpensesCollection else {
            completion?()
            return
        }
        
        legacyCollection.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion?()
                return
            }
            
            let batch = Firestore.firestore().batch()
            documents.forEach { document in
                batch.setData(document.data(), forDocument: currentCollection.document(document.documentID), merge: true)
            }
            
            batch.commit { _ in
                completion?()
            }
        }
    }
    
    static func addExpense(_ data: [String: Any], completion: @escaping (Error?) -> Void) {
        let documentID = UUID().uuidString
        writeExpense(id: documentID, data: data, completion: completion)
    }
    
    static func writeExpense(id: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        guard let primaryReference = primaryExpenseDocumentReference(id: id) else {
            completion(StoreError.notAuthenticated)
            return
        }
        
        primaryReference.setData(data, merge: true) { primaryError in
            if let primaryError = primaryError {
                writeFallbackExpense(id: id, data: data, originalError: primaryError, completion: completion)
                return
            }
            
            mirrorExpense(id: id, data: data, excluding: primaryReference)
            completion(nil)
        }
    }
    
    static func updateExpense(id: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        writeExpense(id: id, data: data, completion: completion)
    }
    
    static func deleteExpenseEverywhere(id: String, completion: ((Error?) -> Void)? = nil) {
        let group = DispatchGroup()
        var firstError: Error?
        
        if let currentCollection = currentExpensesCollection {
            group.enter()
            currentCollection.document(id).delete { error in
                firstError = firstError ?? error
                group.leave()
            }
        }
        
        if let legacyCollection = legacyExpensesCollection {
            group.enter()
            legacyCollection.document(id).delete { error in
                firstError = firstError ?? error
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion?(firstError)
        }
    }
    
    private static func writeFallbackExpense(
        id: String,
        data: [String: Any],
        originalError: Error,
        completion: @escaping (Error?) -> Void
    ) {
        guard let fallbackReference = fallbackExpenseDocumentReference(id: id) else {
            completion(originalError)
            return
        }
        
        fallbackReference.setData(data, merge: true) { fallbackError in
            completion(fallbackError ?? nil)
        }
    }
    
    private static func mirrorExpense(id: String, data: [String: Any], excluding primaryReference: DocumentReference) {
        expenseDocumentReferences(id: id)
            .filter { $0.path != primaryReference.path }
            .forEach { reference in
                reference.setData(data, merge: true) { _ in }
            }
    }
    
    private static func primaryExpenseDocumentReference(id: String) -> DocumentReference? {
        if let legacyCollection = legacyExpensesCollection {
            return legacyCollection.document(id)
        }
        return currentExpensesCollection?.document(id)
    }
    
    private static func fallbackExpenseDocumentReference(id: String) -> DocumentReference? {
        guard let currentReference = currentExpensesCollection?.document(id),
              currentReference.path != primaryExpenseDocumentReference(id: id)?.path else {
            return nil
        }
        return currentReference
    }
    
    private static func expenseDocumentReferences(id: String) -> [DocumentReference] {
        var references: [DocumentReference] = []
        if let legacyCollection = legacyExpensesCollection {
            references.append(legacyCollection.document(id))
        }
        if let currentCollection = currentExpensesCollection {
            references.append(currentCollection.document(id))
        }
        return references
    }
    
    private static var currentOwnerDocumentID: String? {
        if let email = currentOwnerEmail, !email.isEmpty {
            return SharedSettingsStore.accountSettingsDocumentID(for: email)
        }
        return Auth.auth().currentUser?.uid
    }
}
