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
            completion(nil)
            return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists let data = snapshot.data() else {
                completion(nil)
                return
            }
            completion(User(uid: uid, dictionary: data))
        }
    }
    
    // MARK: - Expense Operations
    
    // CREATE
    func addExpense(_ expense: Expense, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            completion(nil)
            return
        }
        
        db.collection("users").document(uid).collection("expenses").addDocument(data: expense.dictionary) { error in
            completion(error == nil)
        }
    }
    
    // READ ALL
    func fetchExpenses(completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let uid = currentUserID else {
            completion([])
            return }
        
        db.collection("users").document(uid).collection("expenses")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                completion([])
                return
            }
                
                let expenses = documents.compactMap {
                    doc -> Expense? in
                    return Expense(id: doc.documentID, dictionary: doc.data())
                }
                completion(expenses)
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
