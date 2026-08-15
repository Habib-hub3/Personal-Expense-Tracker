//
//  Expense.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import Foundation
import FirebaseFirestore

struct Expense{
    let id: String
    let title: String
    let amount: Double
    let category: String
    let date: Date
    let notes: String?
    
    //Initializer for local creation
    init(id: String = UUID().uuidString, title: String, amount: Double, category: String, date: Date = Date(), notes: String? = nil)
    {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
    }
    
    // Convert Firestore Document into Swift Expense model
    init?(id: String, dictionary: [String: Any])
    {
        guard let title = dictionary["title"] as? String,
              let amount = dictionary["amount"] as? Double,
              let category = dictionary["category"] as? String else{
            return nil
        }
              
                self.id = id
                self.title = title
                self.amount = amount
                self.category = category
                
                if let timestamp = dictionary["date"] as? Timestamp {
                    self.date = timestamp.dateValue()
                }else{
                    self.date = Date()
                }
        self.notes = dictionary["notes"] as? String
    }
    
    var dictionary: [String: Any] {
        [
            "title": title,
            "amount": amount,
            "category": category,
            "date": FieldValue.serverTimestamp(),
            "notes": notes ?? ""
        ]
    }
}
