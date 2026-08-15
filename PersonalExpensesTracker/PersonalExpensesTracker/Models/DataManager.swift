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
    static let shared = DataManager()
    private let db = Firestore.firestore()
    private let dataError = NSError(
        domain: "PersonalExpensesTracker.DataManager",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to load the requested data."]
    )
    
    private init() {}
    
    //Current Logged In User ID helper
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    //MARK: - User Profile Operation
    
    func saveUserProfile(user: User, completion: @escaping (Bool) -> Void)
    {
        db.collection("users").document(user.uid).setData(user.dictionary, merge: true) { error in
            completion(error == nil)
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
            
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let data = snapshot.data(),
                  let user = User(uid: uid, dictionary: data) else {
                completion(.failure(self.dataError))
                return
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Expense Operations
    
    // CREATE
    func addExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("expenses").addDocument(data: expense.dictionary) { error in
            completion(error == nil)
        }
    }
    
    // READ ALL
    func fetchExpenses(completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let uid = currentUserID else {
            completion(.failure(dataError))
            return }
        
        db.collection("users").document(uid).collection("expenses")
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
    
    // UPDATE
    func updateExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("expenses").document(expense.id).updateData(expense.dictionary) { error in
            completion(error == nil)
        }
    }
    
    // DELETE
    func deleteExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("expenses").document(expense.id).delete { error in
            completion(error == nil)
        }
    }
}
