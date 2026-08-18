//
//  CategoryImageProvider.swift
//  PersonalExpensesTracker
//

import UIKit

enum CategoryImageProvider {
    static func image(
        for category: String,
        size: CGSize = CGSize(width: 320, height: 200),
        traitCollection: UITraitCollection = .current
    ) -> UIImage {
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cacheKey = cacheKey(for: normalizedCategory, size: size, traitCollection: traitCollection)
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        let style = style(for: normalizedCategory)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        format.preferredRange = .standard
        
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            let backgroundColor = isDarkMode ? style.darkBackground : style.lightBackground
            let accentColor = isDarkMode ? style.darkAccent : style.lightAccent
            let symbolColor = isDarkMode ? style.darkSymbol : style.lightSymbol
            
            backgroundColor.setFill()
            cgContext.fill(rect)
            
            drawAccentShapes(in: rect, color: accentColor.withAlphaComponent(isDarkMode ? 0.26 : 0.18))
            drawSymbol(style.symbolName, in: rect, color: symbolColor)
            drawCategoryLabel(style.title, in: rect, color: symbolColor)
        }
        
        imageCache.setObject(image, forKey: cacheKey as NSString)
        return image
    }
    
    private struct CategoryStyle {
        let title: String
        let symbolName: String
        let lightBackground: UIColor
        let darkBackground: UIColor
        let lightAccent: UIColor
        let darkAccent: UIColor
        let lightSymbol: UIColor
        let darkSymbol: UIColor
    }
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    private static func cacheKey(for category: String, size: CGSize, traitCollection: UITraitCollection) -> String {
        "\(category)-\(Int(size.width))x\(Int(size.height))-\(traitCollection.userInterfaceStyle.rawValue)"
    }
    
    private static func style(for category: String) -> CategoryStyle {
        switch category {
        case "food":
            return CategoryStyle(title: "Food", symbolName: "fork.knife", lightBackground: UIColor(red: 0.96, green: 0.99, blue: 0.91, alpha: 1), darkBackground: UIColor(red: 0.10, green: 0.16, blue: 0.10, alpha: 1), lightAccent: .systemGreen, darkAccent: .systemGreen, lightSymbol: UIColor(red: 0.18, green: 0.47, blue: 0.17, alpha: 1), darkSymbol: UIColor(red: 0.68, green: 0.94, blue: 0.59, alpha: 1))
        case "transport":
            return CategoryStyle(title: "Transport", symbolName: "bus.fill", lightBackground: UIColor(red: 0.91, green: 0.97, blue: 1.00, alpha: 1), darkBackground: UIColor(red: 0.08, green: 0.13, blue: 0.18, alpha: 1), lightAccent: .systemBlue, darkAccent: .systemCyan, lightSymbol: UIColor(red: 0.10, green: 0.36, blue: 0.65, alpha: 1), darkSymbol: UIColor(red: 0.62, green: 0.86, blue: 1.00, alpha: 1))
        case "shopping":
            return CategoryStyle(title: "Shopping", symbolName: "cart.fill", lightBackground: UIColor(red: 1.00, green: 0.94, blue: 0.98, alpha: 1), darkBackground: UIColor(red: 0.18, green: 0.09, blue: 0.15, alpha: 1), lightAccent: .systemPink, darkAccent: .systemPink, lightSymbol: UIColor(red: 0.67, green: 0.12, blue: 0.39, alpha: 1), darkSymbol: UIColor(red: 1.00, green: 0.66, blue: 0.82, alpha: 1))
        case "bills":
            return CategoryStyle(title: "Bills", symbolName: "doc.text.fill", lightBackground: UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1), darkBackground: UIColor(red: 0.13, green: 0.13, blue: 0.17, alpha: 1), lightAccent: .systemIndigo, darkAccent: .systemIndigo, lightSymbol: UIColor(red: 0.28, green: 0.25, blue: 0.62, alpha: 1), darkSymbol: UIColor(red: 0.74, green: 0.72, blue: 1.00, alpha: 1))
        case "entertainment":
            return CategoryStyle(title: "Entertainment", symbolName: "film.fill", lightBackground: UIColor(red: 1.00, green: 0.95, blue: 0.90, alpha: 1), darkBackground: UIColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1), lightAccent: .systemOrange, darkAccent: .systemOrange, lightSymbol: UIColor(red: 0.65, green: 0.32, blue: 0.03, alpha: 1), darkSymbol: UIColor(red: 1.00, green: 0.78, blue: 0.45, alpha: 1))
        case "utilities":
            return CategoryStyle(title: "Utilities", symbolName: "bolt.fill", lightBackground: UIColor(red: 1.00, green: 0.98, blue: 0.88, alpha: 1), darkBackground: UIColor(red: 0.17, green: 0.15, blue: 0.07, alpha: 1), lightAccent: .systemYellow, darkAccent: .systemYellow, lightSymbol: UIColor(red: 0.55, green: 0.43, blue: 0.00, alpha: 1), darkSymbol: UIColor(red: 1.00, green: 0.88, blue: 0.34, alpha: 1))
        case "health":
            return CategoryStyle(title: "Health", symbolName: "heart.fill", lightBackground: UIColor(red: 1.00, green: 0.94, blue: 0.94, alpha: 1), darkBackground: UIColor(red: 0.18, green: 0.08, blue: 0.09, alpha: 1), lightAccent: .systemRed, darkAccent: .systemRed, lightSymbol: UIColor(red: 0.72, green: 0.11, blue: 0.16, alpha: 1), darkSymbol: UIColor(red: 1.00, green: 0.64, blue: 0.67, alpha: 1))
        case "other":
            return CategoryStyle(title: "Other", symbolName: "questionmark.circle.fill", lightBackground: UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1), darkBackground: UIColor(red: 0.12, green: 0.13, blue: 0.14, alpha: 1), lightAccent: .systemGray, darkAccent: .systemGray, lightSymbol: UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1), darkSymbol: UIColor(red: 0.82, green: 0.84, blue: 0.87, alpha: 1))
        default:
            return CategoryStyle(title: "General", symbolName: "tag.fill", lightBackground: UIColor(red: 0.93, green: 0.98, blue: 0.96, alpha: 1), darkBackground: UIColor(red: 0.08, green: 0.15, blue: 0.13, alpha: 1), lightAccent: .systemTeal, darkAccent: .systemTeal, lightSymbol: UIColor(red: 0.08, green: 0.45, blue: 0.39, alpha: 1), darkSymbol: UIColor(red: 0.55, green: 0.92, blue: 0.84, alpha: 1))
        }
    }
    
    private static func drawAccentShapes(in rect: CGRect, color: UIColor) {
        color.setFill()
        UIBezierPath(ovalIn: CGRect(x: rect.maxX - rect.width * 0.34, y: -rect.height * 0.16, width: rect.width * 0.5, height: rect.width * 0.5)).fill()
        UIBezierPath(ovalIn: CGRect(x: -rect.width * 0.18, y: rect.maxY - rect.width * 0.32, width: rect.width * 0.44, height: rect.width * 0.44)).fill()
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: rect.width * 0.10, y: rect.height * 0.76))
        linePath.addLine(to: CGPoint(x: rect.width * 0.90, y: rect.height * 0.76))
        linePath.lineWidth = max(2, rect.height * 0.018)
        linePath.lineCapStyle = .round
        linePath.stroke()
    }
    
    private static func drawSymbol(_ name: String, in rect: CGRect, color: UIColor) {
        let symbolSize = min(rect.width, rect.height) * 0.34
        let configuration = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
        guard let symbol = UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(color, renderingMode: .alwaysOriginal) else { return }
        let symbolRect = CGRect(
            x: rect.midX - symbolSize / 2,
            y: rect.height * 0.22,
            width: symbolSize,
            height: symbolSize
        )
        symbol.draw(in: symbolRect)
    }
    
    private static func drawCategoryLabel(_ title: String, in rect: CGRect, color: UIColor) {
        let fontSize = max(14, min(24, rect.height * 0.11))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: color
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        let titleSize = attributedTitle.size()
        let titleRect = CGRect(
            x: max(12, rect.midX - titleSize.width / 2),
            y: rect.height * 0.80,
            width: min(titleSize.width, rect.width - 24),
            height: titleSize.height
        )
        attributedTitle.draw(in: titleRect)
    }
}
