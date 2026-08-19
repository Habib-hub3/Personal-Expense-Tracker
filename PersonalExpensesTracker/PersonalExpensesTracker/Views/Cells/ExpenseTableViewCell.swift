//
//  ExpenseTableViewCell.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
        @IBOutlet weak var categoryImageView: UIImageView!
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet weak var categoryLabel: UILabel!
        @IBOutlet weak var amountLabel: UILabel!
        @IBOutlet weak var dateLabel: UILabel!
        @IBOutlet weak var editButton: UIButton!

        // MARK: - State
    
        private let editButtonColor = UIColor(red: 0.4524506542, green: 0.6243542933, blue: 0.07266952616, alpha: 1)
        private var currentReceiptURL: String?
        private var isShowingCategoryFallback = false

        // MARK: - Lifecycle
    
        override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
            registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
                (self: Self, _: UITraitCollection) in
                self.applyAdaptiveStyle()
                self.updateCategoryFallbackImageIfNeeded()
            }
        }
    
        override func prepareForReuse() {
            super.prepareForReuse()
            currentReceiptURL = nil
            isShowingCategoryFallback = false
            categoryImageView?.image = nil
            applyEditButtonColor()
        }

        // MARK: - UI Setup
    
        private func setupUI() {
            applyAdaptiveStyle()
            amountLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            categoryImageView?.contentMode = .scaleAspectFit
            categoryImageView?.clipsToBounds = true
            categoryImageView?.layer.cornerRadius = 8
            categoryImageView?.tintColor = .systemBlue
        }
    
        func applyAdaptiveStyle() {
            FormControlStyler.applyCellStyle(to: self)
            titleLabel?.textColor = .label
            amountLabel?.textColor = .label
            categoryLabel?.textColor = .secondaryLabel
            dateLabel?.textColor = .tertiaryLabel
            applyEditButtonColor()
        }
    
        private func applyEditButtonColor() {
            editButton?.tintColor = editButtonColor
            editButton?.setTitleColor(.white, for: .normal)
            editButton?.setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            editButton?.configuration?.baseBackgroundColor = editButtonColor
            editButton?.configuration?.baseForegroundColor = .white
        }

        // MARK: - Configuration
    
        func configure(with expense: Expense) {
            titleLabel?.text = expense.title
            categoryLabel?.text = expense.category
            amountLabel?.text = CurrencyConverter.formattedAmount(fromUSD: expense.amount)
            setThumbnail(for: expense)
            applyAdaptiveStyle()
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateLabel?.text = formatter.string(from: expense.date)
        }
    
        // MARK: - Receipt Thumbnail
    
        private func setThumbnail(for expense: Expense) {
            if let image = image(fromBase64: expense.receiptImageBase64) {
                currentReceiptURL = nil
                isShowingCategoryFallback = false
                categoryImageView?.tintColor = nil
                categoryImageView?.contentMode = .scaleAspectFill
                categoryImageView?.image = image
                return
            }
            
            if let urlString = expense.receiptImageURL,
               let url = URL(string: urlString) {
                currentReceiptURL = urlString
                isShowingCategoryFallback = false
                categoryImageView?.tintColor = nil
                categoryImageView?.contentMode = .scaleAspectFit
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
            isShowingCategoryFallback = true
            categoryImageView?.tintColor = nil
            categoryImageView?.contentMode = .scaleAspectFit
            categoryImageView?.image = CategoryImageProvider.image(
                for: expense.category,
                size: CGSize(width: 120, height: 120),
                traitCollection: traitCollection
            )
        }
    
        private func updateCategoryFallbackImageIfNeeded() {
            guard isShowingCategoryFallback,
                  let category = categoryLabel?.text else { return }
            categoryImageView?.image = CategoryImageProvider.image(
                for: category,
                size: CGSize(width: 120, height: 120),
                traitCollection: traitCollection
            )
        }
    
        // MARK: - Helpers
    
        private func image(fromBase64 value: String?) -> UIImage? {
            guard let value,
                  !value.isEmpty,
                  let data = Data(base64Encoded: value) else {
                return nil
            }
            return UIImage(data: data)
        }

}
