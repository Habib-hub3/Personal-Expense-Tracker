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
    let receiptImageBase64: String?
    let receiptImageURL: String?
    
    var hasReceiptImage: Bool {
        !(receiptImageURL?.isEmpty ?? true) || !(receiptImageBase64?.isEmpty ?? true)
    }
    
    //Initializer for local creation
    init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        category: String,
        date: Date = Date(),
        notes: String? = nil,
        receiptImageBase64: String? = nil,
        receiptImageURL: String? = nil
    )
    {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.receiptImageBase64 = receiptImageBase64
        self.receiptImageURL = receiptImageURL
    }
    
    // Convert Firestore Document into Swift Expense model
    init?(id: String, dictionary: [String: Any])
    {
        guard let title = dictionary["title"] as? String,
              let category = dictionary["category"] as? String else{
            return nil
        }
              
                self.id = id
                self.title = title
                self.amount = Self.amountValue(from: dictionary["amount"])
                self.category = category
                
                if let timestamp = dictionary["date"] as? Timestamp {
                    self.date = timestamp.dateValue()
                }else{
                    self.date = Date()
                }
        self.notes = dictionary["notes"] as? String
        self.receiptImageBase64 = dictionary["receiptImageBase64"] as? String
        self.receiptImageURL = dictionary["receiptImageURL"] as? String
    }
    
    var dictionary: [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "amount": amount,
            "baseCurrencyCode": "USD",
            "category": category,
            "date": FieldValue.serverTimestamp(),
            "notes": notes ?? ""
        ]
        
        if let receiptImageURL {
            data["receiptImageURL"] = receiptImageURL
        }
        
        if let receiptImageBase64 {
            data["receiptImageBase64"] = receiptImageBase64
        }
        
        return data
    }
    
    private static func amountValue(from value: Any?) -> Double {
        if let amount = value as? Double {
            return amount
        }
        if let amount = value as? Int {
            return Double(amount)
        }
        if let amount = value as? NSNumber {
            return amount.doubleValue
        }
        if let amountText = value as? String {
            return Double(amountText) ?? 0
        }
        return 0
    }
}
