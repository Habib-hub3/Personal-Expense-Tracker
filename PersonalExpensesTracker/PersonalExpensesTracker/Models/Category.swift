//
//  Category.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import Foundation

enum ExpenseCategory: String, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case general = "General"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case health = "Health"
    case other = "Other"
    
    static var names: [String] {
        allCases.map(\.rawValue)
    }
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "bus.fill"
        case .shopping: return "cart.fill"
        case .bills: return "doc.text.fill"
        case .general: return "tag.fill"
        case .entertainment: return "film.fill"
        case .utilities: return "bolt.fill"
        case .health: return "heart.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
