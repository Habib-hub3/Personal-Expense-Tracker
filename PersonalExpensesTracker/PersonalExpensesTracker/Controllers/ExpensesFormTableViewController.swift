//
//  ExpensesFormTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ExpensesFormTableViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - IBOutlets
        @IBOutlet weak var titleTextField: UITextField!
        @IBOutlet weak var amountTextField: UITextField!
        @IBOutlet weak var categoryButton: UIButton!
        @IBOutlet weak var datePicker: UIDatePicker!
        @IBOutlet weak var receiptImageView: UIImageView!
        @IBOutlet weak var saveButton: UIBarButtonItem!

        // MARK: - Properties
        /// If `expenseToEdit` is provided, the screen operates in EDIT mode; otherwise, it operates in ADD mode.
        var expenseToEdit: Expense?

        private let categories = ExpenseCategory.names
        private var selectedCategory: String = "General"

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            populateDataIfEditing()
            configureTableLayout()
        }

        // MARK: - UI Setup
        private func setupUI() {
            title = expenseToEdit != nil ? "Edit Expense" : "Add Expense"
            
            let defaultCat = UserDefaults.standard.string(forKey: "defaultCategory") ?? "General"
            selectedCategory = expenseToEdit?.category ?? defaultCat
            updateCategoryButtonTitle()

            configureCategoryMenu()
            setupReceiptImageView()
            setupNavigationItems()
            setupAmountTextField()

            // Navigation bar Cancel button
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonTapped)
            )
        }

        private func updateCategoryButtonTitle() {
            categoryButton.setTitle(selectedCategory, for: .normal)
        }
    
        private func setupNavigationItems() {
            saveButton?.tintColor = .systemBlue
            navigationItem.rightBarButtonItem?.tintColor = .systemBlue
        }

        private func setupAmountTextField() {
            amountTextField.keyboardType = .decimalPad
            amountTextField.delegate = self
        }
    
        private func configureCategoryMenu() {
            let categoryActions = categories.map { category in
                UIAction(title: category, state: category == selectedCategory ? .on : .off) { [weak self] _ in
                    self?.selectedCategory = category
                    self?.updateCategoryButtonTitle()
                    self?.configureCategoryMenu()
                }
            }
            categoryButton.menu = UIMenu(title: "Select Category", children: categoryActions)
            categoryButton.showsMenuAsPrimaryAction = true
        }

        private func populateDataIfEditing() {
            guard let expense = expenseToEdit else { return }
            titleTextField.text = expense.title
            let convertedAmount = CurrencyConverter.convertedAmount(fromUSD: expense.amount)
            amountTextField.text = String(format: "%.2f", convertedAmount)
            datePicker.date = expense.date
            setReceiptImage(for: expense)
            saveButton.title = "Update"
        }

        @objc private func cancelButtonTapped() {
            returnToExpensesScene()
        }

        // MARK: - IBActions
        @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
            guard let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !titleText.isEmpty,
                  let amountText = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let amount = Double(amountText), amount > 0 else {
                showAlert(title: "Invalid Input", message: "Please enter a valid title and amount.")
                return
            }

            guard let uid = Auth.auth().currentUser?.uid else {
                showAlert(title: "Error", message: "User not authenticated.")
                return
            }
            
            let selectedCurrency = CurrencyConverter.selectedCurrencyDisplayName
            let amountInUSD = CurrencyConverter.usdAmount(from: amount, currencyDisplayName: selectedCurrency)
            saveButton.isEnabled = false

            var expenseData: [String: Any] = [
                "title": titleText,
                "amount": amountInUSD,
                "baseCurrencyCode": "USD",
                "entryCurrencyCode": CurrencyConverter.code(from: selectedCurrency),
                "category": selectedCategory,
                "date": Timestamp(date: datePicker.date),
                "createdByUserID": uid,
                "ownerEmail": ExpenseStore.currentOwnerEmail ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            if let receiptImageURL = expenseToEdit?.receiptImageURL, !receiptImageURL.isEmpty {
                expenseData["receiptImageURL"] = receiptImageURL
            }
            if let receiptImageBase64 = expenseToEdit?.receiptImageBase64, !receiptImageBase64.isEmpty {
                expenseData["receiptImageBase64"] = receiptImageBase64
            }

            if let expense = expenseToEdit {
                // UPDATE existing document
                ExpenseStore.updateExpense(id: expense.id, data: expenseData) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.saveButton.isEnabled = true
                        if let error = error {
                            self?.showAlert(title: "Update Error", message: error.localizedDescription)
                        } else {
                            self?.showSuccessAndReturnToExpenses(title: "Expense Updated", message: "Your expense was updated successfully.")
                        }
                    }
                }
            } else {
                // CREATE new document
                ExpenseStore.addExpense(expenseData) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.saveButton.isEnabled = true
                        if let error = error {
                            self?.showAlert(title: "Save Error", message: error.localizedDescription)
                        } else {
                            self?.showSuccessAndReturnToExpenses(title: "Expense Added", message: "Your expense was saved successfully.")
                        }
                    }
                }
            }
        }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
        private func showSuccessAndReturnToExpenses(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.returnToExpensesScene()
            })
            present(alert, animated: true)
        }
    
        private func returnToExpensesScene() {
            guard let tabBarController = tabBarController else { return }
            tabBarController.selectedIndex = 0
            
            if let expensesNavigationController = tabBarController.selectedViewController as? UINavigationController {
                expensesNavigationController.popToRootViewController(animated: false)
            }
        }
    
        private func setupReceiptImageView() {
            receiptImageView.image = UIImage(systemName: "photo")
            receiptImageView.tintColor = .secondaryLabel
            receiptImageView.contentMode = .scaleAspectFit
            receiptImageView.isUserInteractionEnabled = false
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

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard textField === amountTextField else { return true }
            return isValidAmountReplacement(in: textField, range: range, replacementString: string)
        }

        private func isValidAmountReplacement(in textField: UITextField, range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty { return true }
            guard string.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789.").inverted) == nil else { return false }

            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            return updatedText.filter { $0 == "." }.count <= 1
        }
    
    
    // MARK: - Layout
    private func configureTableLayout() {
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.sectionHeaderTopPadding = 12
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.insetsContentViewsToSafeArea = true
    }
}
