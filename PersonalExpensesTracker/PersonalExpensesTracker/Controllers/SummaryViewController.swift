//
//  SummaryViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SummaryViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var totalSpentLabel: UILabel!
    @IBOutlet weak var averageSpentLabel: UILabel?
    @IBOutlet weak var totalCountLabel: UILabel?
    @IBOutlet weak var overallButton: UIButton?
    @IBOutlet weak var monthlyButton: UIButton?
    
    // MARK: - Summary Models
    private enum SummaryScope {
        case overall
        case currentMonth
    }
    
    private struct CategorySummary {
        let category: String
        let amount: Double
        let isHighest: Bool
    }
    
    private struct SummaryExpense {
        let title: String
        let category: String
        let amount: Double
        let date: Date
    }
    
    private let summaryCategories = ExpenseCategory.names
    private let allCategoriesTitle = "All Categories"
    private let categoryButton = UIButton(type: .system)
    private let selectedCategoryTotalLabel = UILabel()
    private let categoryProgressStackView = UIStackView()
    private let selectedCategoryDetailsLabel = UITextView()
    private var categoryProgressHeightConstraint: NSLayoutConstraint?
    private var selectedCategoryDetailsHeightConstraint: NSLayoutConstraint?
    
    private var selectedScope: SummaryScope = .overall
    private var selectedCategory: String?
    private var totalSpent: Double = 0
    // MARK: - State
    
    private var categoryBreakdown: [String: Double] = [:]
    private var categorySummaries: [CategorySummary] = []
    private var summaryExpenses: [SummaryExpense] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCategoryControls()
        setupResponsiveLayout()
        updateScopeButtons()
        updateCategoryMenu()
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
            (self: Self, _: UITraitCollection) in
            self.updateScopeButtons()
            FormControlStyler.styleMenuButton(self.categoryButton, title: self.selectedCategory ?? self.allCategoriesTitle)
        }
        observeSharedSettingsChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSummaryData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupCategoryControls() {
        view.addSubview(categoryButton)
        view.addSubview(selectedCategoryTotalLabel)
        view.addSubview(categoryProgressStackView)
        view.addSubview(selectedCategoryDetailsLabel)
        
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        selectedCategoryTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryProgressStackView.translatesAutoresizingMaskIntoConstraints = false
        selectedCategoryDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.changesSelectionAsPrimaryAction = true
        FormControlStyler.styleMenuButton(categoryButton, title: allCategoriesTitle)
        
        selectedCategoryTotalLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .boldSystemFont(ofSize: 34))
        selectedCategoryTotalLabel.adjustsFontForContentSizeCategory = true
        selectedCategoryTotalLabel.textAlignment = .center
        selectedCategoryTotalLabel.numberOfLines = 2
        selectedCategoryTotalLabel.adjustsFontSizeToFitWidth = true
        selectedCategoryTotalLabel.minimumScaleFactor = 0.65
        
        categoryProgressStackView.axis = .vertical
        categoryProgressStackView.spacing = 8
        categoryProgressStackView.alignment = .fill
        
        selectedCategoryDetailsLabel.font = .preferredFont(forTextStyle: .body)
        selectedCategoryDetailsLabel.adjustsFontForContentSizeCategory = true
        selectedCategoryDetailsLabel.textColor = .secondaryLabel
        selectedCategoryDetailsLabel.textAlignment = .left
        selectedCategoryDetailsLabel.isEditable = false
        selectedCategoryDetailsLabel.isSelectable = false
        selectedCategoryDetailsLabel.isScrollEnabled = true
        selectedCategoryDetailsLabel.backgroundColor = .clear
        selectedCategoryDetailsLabel.textContainerInset = .zero
        selectedCategoryDetailsLabel.textContainer.lineFragmentPadding = 0
        selectedCategoryDetailsLabel.isHidden = true
    }
    
    // MARK: - Settings Sync
    
    private func observeSharedSettingsChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sharedSettingsChanged),
            name: SharedSettingsStore.settingsDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func sharedSettingsChanged() {
        fetchSummaryData()
    }
    
    // MARK: - Layout
    
    private func setupResponsiveLayout() {
        guard let summaryCard = totalSpentLabel.superview,
              let overallButton = overallButton,
              let monthlyButton = monthlyButton else { return }
        
        let summaryTitleLabel = summaryCard.subviews
            .compactMap { $0 as? UILabel }
            .first { $0 !== totalSpentLabel }
        let managedViews: [UIView] = [overallButton, monthlyButton, summaryCard, categoryButton, selectedCategoryTotalLabel, categoryProgressStackView, selectedCategoryDetailsLabel]
        
        managedViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        summaryTitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        totalSpentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            managedViews.contains { managedView in
                constraint.firstItem === managedView || constraint.secondItem === managedView
            }
        })
        NSLayoutConstraint.deactivate(summaryCard.constraints)
        NSLayoutConstraint.deactivate(overallButton.constraints)
        NSLayoutConstraint.deactivate(monthlyButton.constraints)
        
        let contentGuide = UILayoutGuide()
        view.addLayoutGuide(contentGuide)
        
        let safeArea = view.safeAreaLayoutGuide
        let contentWidthConstraint = contentGuide.widthAnchor.constraint(equalTo: safeArea.widthAnchor, constant: -32)
        contentWidthConstraint.priority = .defaultHigh
        
        totalSpentLabel.numberOfLines = 2
        totalSpentLabel.textAlignment = .center
        totalSpentLabel.adjustsFontSizeToFitWidth = true
        totalSpentLabel.minimumScaleFactor = 0.55
        summaryTitleLabel?.textAlignment = .center
        summaryTitleLabel?.adjustsFontSizeToFitWidth = true
        summaryTitleLabel?.minimumScaleFactor = 0.75
        summaryCard.layer.cornerRadius = 10
        summaryCard.clipsToBounds = true
        
        let progressHeightConstraint = categoryProgressStackView.heightAnchor.constraint(equalToConstant: 0)
        progressHeightConstraint.isActive = false
        categoryProgressHeightConstraint = progressHeightConstraint
        
        let detailsHeightConstraint = selectedCategoryDetailsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        selectedCategoryDetailsHeightConstraint = detailsHeightConstraint
        
        var constraints: [NSLayoutConstraint] = [
            contentGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            contentGuide.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            contentGuide.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 16),
            contentGuide.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -16),
            contentGuide.widthAnchor.constraint(lessThanOrEqualToConstant: 700),
            contentWidthConstraint,
            
            overallButton.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            overallButton.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            overallButton.heightAnchor.constraint(equalToConstant: 44),
            
            monthlyButton.topAnchor.constraint(equalTo: overallButton.topAnchor),
            monthlyButton.leadingAnchor.constraint(equalTo: overallButton.trailingAnchor, constant: 12),
            monthlyButton.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            monthlyButton.widthAnchor.constraint(equalTo: overallButton.widthAnchor),
            monthlyButton.heightAnchor.constraint(equalTo: overallButton.heightAnchor),
            
            summaryCard.topAnchor.constraint(equalTo: overallButton.bottomAnchor, constant: 12),
            summaryCard.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            summaryCard.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            summaryCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 118),
            
            totalSpentLabel.centerXAnchor.constraint(equalTo: summaryCard.centerXAnchor),
            totalSpentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: summaryCard.leadingAnchor, constant: 16),
            totalSpentLabel.trailingAnchor.constraint(lessThanOrEqualTo: summaryCard.trailingAnchor, constant: -16),
            
            categoryButton.topAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            categoryButton.heightAnchor.constraint(equalToConstant: 44),
            
            selectedCategoryTotalLabel.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 18),
            selectedCategoryTotalLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            selectedCategoryTotalLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            
            categoryProgressStackView.topAnchor.constraint(equalTo: selectedCategoryTotalLabel.bottomAnchor, constant: 14),
            categoryProgressStackView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            categoryProgressStackView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            
            selectedCategoryDetailsLabel.topAnchor.constraint(equalTo: categoryProgressStackView.bottomAnchor, constant: 14),
            selectedCategoryDetailsLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            selectedCategoryDetailsLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            detailsHeightConstraint,
            selectedCategoryDetailsLabel.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -16)
        ]
        
        if let summaryTitleLabel = summaryTitleLabel {
            constraints.append(contentsOf: [
                summaryTitleLabel.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 20),
                summaryTitleLabel.centerXAnchor.constraint(equalTo: summaryCard.centerXAnchor),
                summaryTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: summaryCard.leadingAnchor, constant: 16),
                summaryTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: summaryCard.trailingAnchor, constant: -16),
                totalSpentLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 10),
                totalSpentLabel.bottomAnchor.constraint(lessThanOrEqualTo: summaryCard.bottomAnchor, constant: -20)
            ])
        } else {
            constraints.append(totalSpentLabel.centerYAnchor.constraint(equalTo: summaryCard.centerYAnchor))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    @IBAction func overallSummaryTapped(_ sender: UIButton) {
        selectedScope = .overall
        updateScopeButtons()
        fetchSummaryData()
    }
    
    @IBAction func monthlySummaryTapped(_ sender: UIButton) {
        selectedScope = .currentMonth
        updateScopeButtons()
        fetchSummaryData()
    }
    
    // MARK: - Summary Loading
    
    private func fetchSummaryData() {
        var expenseDocuments: [String: [String: Any]] = [:]
        let mergeQueue = DispatchQueue(label: "PersonalExpensesTracker.summaryMerge")
        let group = DispatchGroup()
        
        if let legacyCollection = ExpenseStore.legacyExpensesCollection {
            group.enter()
            legacyCollection.getDocuments { snapshot, _ in
                mergeQueue.async {
                    snapshot?.documents.forEach { document in
                        expenseDocuments[document.documentID] = document.data()
                    }
                    group.leave()
                }
            }
        }
        
        if let sharedCollection = ExpenseStore.currentExpensesCollection {
            group.enter()
            sharedCollection.getDocuments { snapshot, _ in
                mergeQueue.async {
                    snapshot?.documents.forEach { document in
                        expenseDocuments[document.documentID] = document.data()
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: mergeQueue) { [weak self] in
            let documents = Array(expenseDocuments.values)
            DispatchQueue.main.async {
                self?.applySummaryDocuments(documents)
            }
        }
        
        ExpenseStore.migrateLegacyExpensesIfNeeded()
    }
    
    // MARK: - Summary Processing
    
    private func applySummaryDocuments(_ documents: [[String: Any]]) {
        var totalSum: Double = 0
        var breakdown: [String: Double] = [:]
        var validExpenseCount = 0
        var expenseItems: [SummaryExpense] = []
        
        for data in documents {
            guard shouldIncludeExpense(data) else { continue }
            
            let amount = expenseAmount(from: data["amount"])
            let category = normalizedCategory(data["category"] as? String)
            let title = expenseTitle(from: data["title"])
            let date = expenseDate(from: data["date"]) ?? .distantPast
            
            totalSum += amount
            breakdown[category, default: 0.0] += amount
            validExpenseCount += 1
            expenseItems.append(SummaryExpense(title: title, category: category, amount: amount, date: date))
        }
        
        expenseItems.sort { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.title < rhs.title
            }
            return lhs.date > rhs.date
        }
        
        let average = validExpenseCount > 0 ? totalSum / Double(validExpenseCount) : 0.0
        let summaries = makeCategorySummaries(from: breakdown)
        
        DispatchQueue.main.async {
            self.totalSpent = totalSum
            self.categoryBreakdown = breakdown
            self.totalSpentLabel.text = "Total Spent: \(CurrencyConverter.formattedAmount(fromUSD: totalSum))"
            self.averageSpentLabel?.text = "Average: \(CurrencyConverter.formattedAmount(fromUSD: average))"
            self.totalCountLabel?.text = "Transactions: \(validExpenseCount)"
            self.categorySummaries = summaries
            self.summaryExpenses = expenseItems
            self.updateCategoryMenu()
            self.updateCategoryProgressBars()
            self.updateSelectedCategoryTotal()
        }
    }
    
    private func makeCategorySummaries(from breakdown: [String: Double]) -> [CategorySummary] {
        let knownCategories = summaryCategories.map { category in
            CategorySummary(category: category, amount: breakdown[category] ?? 0, isHighest: false)
        }
        
        let extraCategories = breakdown.keys
            .filter { !summaryCategories.contains($0) }
            .map { CategorySummary(category: $0, amount: breakdown[$0] ?? 0, isHighest: false) }
        
        let allSummaries = knownCategories + extraCategories
        let highestAmount = allSummaries.map(\.amount).max() ?? 0
        
        return allSummaries
            .map { summary in
                CategorySummary(
                    category: summary.category,
                    amount: summary.amount,
                    isHighest: highestAmount > 0 && summary.amount == highestAmount
                )
            }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount {
                    return lhs.category < rhs.category
                }
                return lhs.amount > rhs.amount
            }
    }
    
    private func shouldIncludeExpense(_ data: [String: Any]) -> Bool {
        switch selectedScope {
        case .overall:
            return true
        case .currentMonth:
            guard let expenseDate = expenseDate(from: data["date"]) else { return false }
            return Calendar.current.isDate(expenseDate, equalTo: Date(), toGranularity: .month)
        }
    }
    
    // MARK: - Summary UI Updates
    
    private func updateScopeButtons() {
        applyScopeStyle(to: overallButton, isSelected: selectedScope == .overall)
        applyScopeStyle(to: monthlyButton, isSelected: selectedScope == .currentMonth)
    }
    
    private func applyScopeStyle(to button: UIButton?, isSelected: Bool) {
        guard let button else { return }
        let title = button.title(for: .normal) ?? button.configuration?.title
        button.isSelected = isSelected
        
        if isSelected {
            FormControlStyler.styleFilledButton(button, title: title, color: .systemBlue)
        } else {
            FormControlStyler.stylePlainButton(button, title: title)
        }
    }
    
    private func updateCategoryMenu() {
        let allAction = UIAction(
            title: allCategoriesTitle,
            image: UIImage(systemName: "tray.full.fill"),
            state: selectedCategory == nil ? .on : .off
        ) { [weak self] _ in
            self?.selectedCategory = nil
            self?.updateCategoryMenu()
            self?.updateSelectedCategoryTotal()
        }
        
        let categoryActions = summaryCategories.map { category in
            UIAction(
                title: category,
                image: UIImage(systemName: categoryIconName(for: category)),
                state: selectedCategory == category ? .on : .off
            ) { [weak self] _ in
                self?.selectedCategory = category
                self?.updateCategoryMenu()
                self?.updateSelectedCategoryTotal()
            }
        }
        
        categoryButton.menu = UIMenu(title: "Choose Category", children: [allAction] + categoryActions)
        FormControlStyler.styleMenuButton(categoryButton, title: selectedCategory ?? allCategoriesTitle)
    }
    
    private func updateCategoryProgressBars() {
        categoryProgressStackView.arrangedSubviews.forEach { view in
            categoryProgressStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        let visibleSummaries = categorySummaries.filter { $0.amount > 0 }
        guard !visibleSummaries.isEmpty else {
            categoryProgressStackView.isHidden = true
            return
        }
        
        categoryProgressStackView.isHidden = false
        let maxAmount = visibleSummaries.map(\.amount).max() ?? 1
        visibleSummaries.forEach { summary in
            categoryProgressStackView.addArrangedSubview(progressRow(for: summary, maxAmount: maxAmount))
        }
    }
    
    private func progressRow(for summary: CategorySummary, maxAmount: Double) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = summary.isHighest ? .systemBlue : .secondaryLabel
        titleLabel.text = "\(summary.category): \(CurrencyConverter.formattedAmount(fromUSD: summary.amount))"
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = maxAmount > 0 ? Float(summary.amount / maxAmount) : 0
        progressView.progressTintColor = summary.isHighest ? .systemBlue : .systemGreen
        progressView.trackTintColor = .systemGray5
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(progressView)
        return stackView
    }
    
    private func updateSelectedCategoryTotal() {
        if let selectedCategory = selectedCategory {
            let amount = categoryBreakdown[selectedCategory] ?? 0
            selectedCategoryTotalLabel.text = "\(selectedCategory)\n\(CurrencyConverter.formattedAmount(fromUSD: amount))"
            selectedCategoryDetailsLabel.text = expenseDetailsText(for: selectedCategory)
            selectedCategoryDetailsLabel.isHidden = false
            selectedCategoryDetailsHeightConstraint?.constant = 110
            categoryProgressStackView.isHidden = true
            categoryProgressHeightConstraint?.isActive = true
        } else {
            selectedCategoryTotalLabel.text = "All Categories\n\(CurrencyConverter.formattedAmount(fromUSD: totalSpent))"
            selectedCategoryDetailsLabel.text = nil
            selectedCategoryDetailsLabel.isHidden = true
            selectedCategoryDetailsHeightConstraint?.constant = 0
            categoryProgressHeightConstraint?.isActive = false
            updateCategoryProgressBars()
        }
        selectedCategoryDetailsLabel.setContentOffset(.zero, animated: false)
    }
    
    // MARK: - Display Text
    
    private func expenseDetailsText(for category: String) -> String {
        let matchingExpenses = summaryExpenses.filter { $0.category == category }
        guard !matchingExpenses.isEmpty else {
            return "No expenses in \(category)."
        }
        
        return matchingExpenses
            .map { "\($0.title): \(CurrencyConverter.formattedAmount(fromUSD: $0.amount))" }
            .joined(separator: "\n")
    }
    
    private func categoryTotalsText() -> String {
        guard !categorySummaries.isEmpty else {
            return "No expenses saved yet."
        }
        
        let lines = categorySummaries
            .filter { $0.amount > 0 }
            .map { "\($0.category): \(CurrencyConverter.formattedAmount(fromUSD: $0.amount))" }
        
        return lines.isEmpty ? "No expenses saved yet." : lines.joined(separator: "\n")
    }
    
    // MARK: - Parsing Helpers
    
    private func normalizedCategory(_ category: String?) -> String {
        guard let category = category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty else {
            return "General"
        }
        return category
    }
    
    private func categoryIconName(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "transport": return "bus.fill"
        case "shopping": return "cart.fill"
        case "bills": return "doc.text.fill"
        case "utilities": return "bolt.fill"
        case "entertainment": return "film.fill"
        case "health": return "heart.fill"
        case "general", "other": return "tag.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func expenseTitle(from value: Any?) -> String {
        let title = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "Untitled Expense" : title
    }
    
    private func expenseAmount(from value: Any?) -> Double {
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
    
    private func expenseDate(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let date = value as? Date {
            return date
        }
        if let timeInterval = value as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return nil
    }
}
