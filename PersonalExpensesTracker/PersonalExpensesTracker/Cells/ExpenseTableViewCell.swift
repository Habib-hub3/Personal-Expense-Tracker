//
//  ExpenseTableViewCell.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
        @IBOutlet weak var categoryImageView: UIImageView!
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet weak var categoryLabel: UILabel!
        @IBOutlet weak var amountLabel: UILabel!
        @IBOutlet weak var dateLabel: UILabel!
        @IBOutlet weak var editButton: UIButton!

        private let editButtonColor = UIColor(red: 0.4524506542, green: 0.6243542933, blue: 0.07266952616, alpha: 1)
        private var currentReceiptURL: String?

        override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
        }
    
        override func prepareForReuse() {
            super.prepareForReuse()
            currentReceiptURL = nil
            categoryImageView?.image = nil
            applyEditButtonColor()
        }

        private func setupUI() {
            // Optional custom styling
            amountLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            categoryLabel?.textColor = .secondaryLabel
            dateLabel?.textColor = .tertiaryLabel
            categoryImageView?.contentMode = .scaleAspectFit
            categoryImageView?.tintColor = .systemBlue
            applyEditButtonColor()
        }
    
        private func applyEditButtonColor() {
            editButton?.tintColor = editButtonColor
            editButton?.setTitleColor(.white, for: .normal)
            editButton?.setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            editButton?.configuration?.baseBackgroundColor = editButtonColor
            editButton?.configuration?.baseForegroundColor = .white
        }

        func configure(with expense: Expense) {
            titleLabel?.text = expense.title
            categoryLabel?.text = expense.category
            amountLabel?.text = CurrencyConverter.formattedAmount(fromUSD: expense.amount)
            setThumbnail(for: expense)
            applyEditButtonColor()
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateLabel?.text = formatter.string(from: expense.date)
        }
    
        private func setThumbnail(for expense: Expense) {
            if let image = image(fromBase64: expense.receiptImageBase64) {
                currentReceiptURL = nil
                categoryImageView?.tintColor = nil
                categoryImageView?.image = image
                return
            }
            
            if let urlString = expense.receiptImageURL,
               let url = URL(string: urlString) {
                currentReceiptURL = urlString
                categoryImageView?.tintColor = nil
                categoryImageView?.image = UIImage(systemName: "photo")
                URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                    guard let self = self,
                          self.currentReceiptURL == urlString,
                          let data = data,
                          let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        guard self.currentReceiptURL == urlString else { return }
                        self.categoryImageView?.image = image
                    }
                }.resume()
                return
            }
            
            currentReceiptURL = nil
            categoryImageView?.tintColor = .systemBlue
            categoryImageView?.image = UIImage(systemName: iconName(for: expense.category))
        }
    
        private func image(fromBase64 value: String?) -> UIImage? {
            guard let value,
                  !value.isEmpty,
                  let data = Data(base64Encoded: value) else {
                return nil
            }
            return UIImage(data: data)
        }
    
        private func iconName(for category: String) -> String {
            switch category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "food":
                return "fork.knife"
            case "transport":
                return "bus.fill"
            case "shopping":
                return "cart.fill"
            case "bills", "utilities":
                return "doc.text.fill"
            case "entertainment":
                return "film.fill"
            case "health":
                return "heart.fill"
            case "general", "other":
                return "tag.fill"
            default:
                return "questionmark.circle.fill"
            }
        }

}
