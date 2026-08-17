//
//  CurrencyConverter.swift
//  PersonalExpensesTracker
//

import Foundation

enum CurrencyConverter {
    private static let usdRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "BHD": 0.377,
        "GBP": 0.79
    ]
    
    static var selectedCurrencyDisplayName: String {
        UserDefaults.standard.string(forKey: "appCurrency") ?? "BHD (BD)"
    }
    
    static func code(from displayName: String) -> String {
        let code = displayName.split(separator: " ").first.map(String.init) ?? displayName
        return code.uppercased()
    }
    
    static func symbol(for displayName: String) -> String {
        switch code(from: displayName) {
        case "USD": return "$"
        case "EUR": return "€"
        case "BHD": return "BD"
        case "GBP": return "£"
        default: return code(from: displayName)
        }
    }
    
    static func usdAmount(from amount: Double, currencyDisplayName: String = selectedCurrencyDisplayName) -> Double {
        let rate = usdRates[code(from: currencyDisplayName)] ?? 1.0
        guard rate > 0 else { return amount }
        return amount / rate
    }
    
    static func convertedAmount(fromUSD amount: Double, currencyDisplayName: String = selectedCurrencyDisplayName) -> Double {
        let rate = usdRates[code(from: currencyDisplayName)] ?? 1.0
        return amount * rate
    }
    
    static func formattedAmount(fromUSD amount: Double, currencyDisplayName: String = selectedCurrencyDisplayName) -> String {
        let convertedAmount = convertedAmount(fromUSD: amount, currencyDisplayName: currencyDisplayName)
        return String(format: "%.2f %@", convertedAmount, symbol(for: currencyDisplayName))
    }
}
