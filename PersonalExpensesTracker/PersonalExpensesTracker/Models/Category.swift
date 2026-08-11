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
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case shopping = "Shopping"
    case health = "Health"
    case other = "Other"
    
    // SF Sympols icon name for each catagory
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "film"
        case .utilities: return "bolt.fill"
        case .shopping: return "cart.fill"
        case .health: return "heart.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
