//
//  ExpenseDetailViewController.swift
//  PersonalExpensesTracker
//

import UIKit

class ExpenseDetailViewController: UIViewController {
    var expense: Expense?
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let receiptImageView = UIImageView()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let categoryLabel = UILabel()
    private let dateLabel = UILabel()
    private let notesLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Expense Detail"
        view.backgroundColor = .systemBackground
        setupLayout()
        configureContent()
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 14
        contentStackView.alignment = .fill
        contentStackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 24, right: 20)
        contentStackView.isLayoutMarginsRelativeArrangement = true
        
        receiptImageView.translatesAutoresizingMaskIntoConstraints = false
        receiptImageView.contentMode = .scaleAspectFit
        receiptImageView.backgroundColor = .secondarySystemBackground
        receiptImageView.tintColor = .secondaryLabel
        receiptImageView.clipsToBounds = true
        receiptImageView.layer.cornerRadius = 8
        
        [titleLabel, amountLabel, categoryLabel, dateLabel, notesLabel].forEach { label in
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        amountLabel.font = .preferredFont(forTextStyle: .title1)
        categoryLabel.font = .preferredFont(forTextStyle: .body)
        dateLabel.font = .preferredFont(forTextStyle: .body)
        notesLabel.font = .preferredFont(forTextStyle: .body)
        amountLabel.textColor = .systemBlue
        
        contentStackView.addArrangedSubview(receiptImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(amountLabel)
        contentStackView.addArrangedSubview(categoryLabel)
        contentStackView.addArrangedSubview(dateLabel)
        contentStackView.addArrangedSubview(notesLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            receiptImageView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }
    
    private func configureContent() {
        guard let expense = expense else { return }
        titleLabel.text = expense.title
        amountLabel.text = CurrencyConverter.formattedAmount(fromUSD: expense.amount)
        categoryLabel.text = "Category: \(expense.category)"
        dateLabel.text = "Date: \(formattedDate(expense.date))"
        notesLabel.text = "Notes: \((expense.notes?.isEmpty == false) ? expense.notes! : "No notes")"
        setReceiptImage(for: expense)
    }
    
    private func setReceiptImage(for expense: Expense) {
        if let image = image(fromBase64: expense.receiptImageBase64) {
            receiptImageView.image = image
            return
        }
        
        guard let urlString = expense.receiptImageURL,
              let url = URL(string: urlString) else {
            receiptImageView.image = UIImage(systemName: "photo")
            return
        }
        
        receiptImageView.image = UIImage(systemName: "photo")
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.receiptImageView.image = image
            }
        }.resume()
    }
    
    private func image(fromBase64 value: String?) -> UIImage? {
        guard let value,
              !value.isEmpty,
              let data = Data(base64Encoded: value) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
