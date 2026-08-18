//
//  ExpensesTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ExpensesTableViewController: UITableViewController, UISearchResultsUpdating {
    
    // MARK: - IBOutlets
    @IBOutlet weak var totalExpensesLabel: UILabel!
    
    // MARK: - Properties
    private var expenses: [Expense] = []
    private var displayedExpenses: [Expense] = []
    private var selectedCategoryFilter: String?
    private var selectedMonthFilter: Date?
    private let searchController = UISearchController(searchResultsController: nil)
    private var sharedListener: ListenerRegistration?
    private var legacyListener: ListenerRegistration?
    private var sharedExpenseDocuments: [String: Expense] = [:]
    private var legacyExpenseDocuments: [String: Expense] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Expenses"
        configureSearchController()
        configureFilterButton()
        fetchExpenses()
        configureTableLayout()
        observeSharedSettingsChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyFilters()
    }
    
    deinit {
        sharedListener?.remove()
        legacyListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Firebase Live Fetching
    private func fetchExpenses() {
        listenToSharedExpenses()
        listenToLegacyExpenses()
        ExpenseStore.migrateLegacyExpensesIfNeeded()
    }
    
    private func listenToSharedExpenses() {
        sharedListener?.remove()
        guard let expensesCollection = ExpenseStore.currentExpensesCollection else { return }
        
        sharedListener = expensesCollection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if error != nil { return }
                self.sharedExpenseDocuments = self.expensesByID(from: snapshot)
                self.applyMergedExpenses()
            }
    }
    
    private func listenToLegacyExpenses() {
        legacyListener?.remove()
        guard let legacyCollection = ExpenseStore.legacyExpensesCollection else { return }
        
        legacyListener = legacyCollection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if error != nil { return }
                self.legacyExpenseDocuments = self.expensesByID(from: snapshot)
                self.applyMergedExpenses()
            }
    }
    
    private func expensesByID(from snapshot: QuerySnapshot?) -> [String: Expense] {
        guard let documents = snapshot?.documents else { return [:] }
        return documents.reduce(into: [:]) { result, document in
            result[document.documentID] = Expense(id: document.documentID, dictionary: document.data())
        }
    }
    
    private func applyMergedExpenses() {
        let mergedDocuments = legacyExpenseDocuments.merging(sharedExpenseDocuments) { _, shared in shared }
        expenses = mergedDocuments.values.sorted { $0.date > $1.date }
        
        DispatchQueue.main.async {
            self.applyFilters()
            self.configureFilterButton()
        }
    }
    
    private func updateTotalHeader() {
        let total = displayedExpenses.reduce(0) { $0 + $1.amount }
        let formattedTotal = CurrencyConverter.formattedAmount(fromUSD: total)
        let prefix = hasActiveFilters ? "Filtered Total" : "Total"
        
        if let headerLabel = totalExpensesLabel {
            headerLabel.text = "\(prefix): \(formattedTotal)"
        } else {
            navigationItem.title = "Expenses - \(prefix): \(formattedTotal)"
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategoryFilter != nil || selectedMonthFilter != nil || !(searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search expenses"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func configureFilterButton() {
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        filterButton.tintColor = hasActiveFilters ? .systemBlue : nil
        navigationItem.rightBarButtonItem = filterButton
    }
    
    @objc private func filterButtonTapped() {
        let filterViewController = ExpenseFilterOptionsViewController(
            categories: ExpenseCategory.names,
            months: availableMonths(),
            selectedCategory: selectedCategoryFilter,
            selectedMonth: selectedMonthFilter
        )
        filterViewController.onSelectionChanged = { [weak self] category, month in
            self?.selectedCategoryFilter = category
            self?.selectedMonthFilter = month
            self?.applyFilters()
            self?.configureFilterButton()
        }
        
        let navigationController = UINavigationController(rootViewController: filterViewController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(navigationController, animated: true)
    }
    
    private func applyFilters() {
        let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        displayedExpenses = expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || expense.title.lowercased().contains(searchText)
            let matchesCategory = selectedCategoryFilter == nil || expense.category == selectedCategoryFilter
            let matchesMonth = selectedMonthFilter == nil || Calendar.current.isDate(expense.date, equalTo: selectedMonthFilter ?? Date(), toGranularity: .month)
            return matchesSearch && matchesCategory && matchesMonth
        }
        updateTotalHeader()
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        applyFilters()
    }
    
    private func availableMonths() -> [Date] {
        let calendar = Calendar.current
        let startsOfMonths = expenses.compactMap { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))
        }
        return Array(Set(startsOfMonths)).sorted(by: >)
    }
    
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func iconName(for category: String) -> String {
        switch category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "food": return "fork.knife"
        case "transport": return "bus.fill"
        case "shopping": return "cart.fill"
        case "bills", "utilities": return "doc.text.fill"
        case "entertainment": return "film.fill"
        case "health": return "heart.fill"
        case "general", "other": return "tag.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func observeSharedSettingsChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sharedSettingsChanged),
            name: SharedSettingsStore.settingsDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func sharedSettingsChanged() {
        applyFilters()
    }
    
    // MARK: - Table View Data Source (Dynamic Cells)
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedExpenses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath) as? ExpenseTableViewCell else {
            return UITableViewCell()
        }
        
        let expense = displayedExpenses[indexPath.row]
        
        cell.configure(with: expense)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let expenseCell = cell as? ExpenseTableViewCell {
            expenseCell.applyAdaptiveStyle()
        } else {
            FormControlStyler.applyCellStyle(to: cell)
        }
    }
    
    // MARK: - Swipe to Delete
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let expenseToDelete = displayedExpenses[indexPath.row]

                // Delete from the shared account store and old UID store if it exists.
                ExpenseStore.deleteExpenseEverywhere(id: expenseToDelete.id) { [weak self] error in
                    if let error = error {
                        self?.showAlert(title: "Error Deleting", message: error.localizedDescription)
                    }
                }
            }
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let detailViewController = ExpenseDetailViewController()
            detailViewController.expense = displayedExpenses[indexPath.row]
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            guard let formViewController = segue.destination as? ExpensesFormTableViewController,
                  let selectedExpense = expenseForEditSegue(sender: sender) else {
                return
            }
            
            formViewController.expenseToEdit = selectedExpense
        }
    
        private func expenseForEditSegue(sender: Any?) -> Expense? {
            if let indexPath = tableView.indexPathForSelectedRow {
                return displayedExpenses[indexPath.row]
            }
            
            if let view = sender as? UIView,
               let cell = enclosingCell(for: view),
               let indexPath = tableView.indexPath(for: cell) {
                return displayedExpenses[indexPath.row]
            }
            
            return nil
        }
    
        private func enclosingCell(for view: UIView) -> UITableViewCell? {
            var currentView: UIView? = view
            while let view = currentView {
                if let cell = view as? UITableViewCell {
                    return cell
                }
                currentView = view.superview
            }
            return nil
        }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    // MARK: - Layout
    private func configureTableLayout() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorColor = .separator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.insetsContentViewsToSafeArea = true
        tableView.contentInsetAdjustmentBehavior = .automatic
    }
}

private final class ExpenseFilterOptionsViewController: UITableViewController {
    var onSelectionChanged: ((String?, Date?) -> Void)?
    
    private let categories: [String]
    private let months: [Date]
    private var selectedCategory: String?
    private var selectedMonth: Date?
    
    init(categories: [String], months: [Date], selectedCategory: String?, selectedMonth: Date?) {
        self.categories = categories
        self.months = months
        self.selectedCategory = selectedCategory
        self.selectedMonth = selectedMonth
        super.init(style: .insetGrouped)
        title = "Filters"
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .systemBackground
        tableView.separatorColor = .separator
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FilterOptionCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Category"
        case 1:
            return "Month"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return categories.count + 1
        case 1:
            return months.count + 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterOptionCell", for: indexPath)
        var configuration = UIListContentConfiguration.cell()
        
        switch indexPath.section {
        case 0:
            let isAllCategoriesRow = indexPath.row == 0
            let category = isAllCategoriesRow ? nil : categories[indexPath.row - 1]
            configuration.text = category ?? "All Categories"
            configuration.image = UIImage(systemName: category.map(iconName(for:)) ?? "tray.full.fill")
            cell.accessoryType = category == selectedCategory ? .checkmark : .none
        case 1:
            let isAllMonthsRow = indexPath.row == 0
            let month = isAllMonthsRow ? nil : months[indexPath.row - 1]
            configuration.text = month.map(formattedMonth) ?? "All Months"
            configuration.image = UIImage(systemName: "calendar")
            cell.accessoryType = monthMatchesSelection(month) ? .checkmark : .none
        default:
            break
        }
        
        configuration.textProperties.color = .label
        configuration.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = configuration
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.tintColor = .systemBlue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            selectedCategory = indexPath.row == 0 ? nil : categories[indexPath.row - 1]
        case 1:
            selectedMonth = indexPath.row == 0 ? nil : months[indexPath.row - 1]
        default:
            break
        }
        
        onSelectionChanged?(selectedCategory, selectedMonth)
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func clearTapped() {
        selectedCategory = nil
        selectedMonth = nil
        onSelectionChanged?(nil, nil)
        tableView.reloadData()
    }
    
    private func monthMatchesSelection(_ month: Date?) -> Bool {
        switch (month, selectedMonth) {
        case (nil, nil):
            return true
        case let (month?, selectedMonth?):
            return Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month)
        default:
            return false
        }
    }
    
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func iconName(for category: String) -> String {
        switch category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "food": return "fork.knife"
        case "transport": return "bus.fill"
        case "shopping": return "cart.fill"
        case "bills", "utilities": return "doc.text.fill"
        case "entertainment": return "film.fill"
        case "health": return "heart.fill"
        case "general", "other": return "tag.fill"
        default: return "questionmark.circle.fill"
        }
    }
}
