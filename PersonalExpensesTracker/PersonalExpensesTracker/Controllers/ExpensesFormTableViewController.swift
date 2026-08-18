//
//  ExpensesFormTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ExpensesFormTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
        @IBOutlet weak var titleTextField: UITextField!
        @IBOutlet weak var amountTextField: UITextField!
        @IBOutlet weak var notesTextField: UITextField!
        @IBOutlet weak var categoryButton: UIButton!
        @IBOutlet weak var datePicker: UIDatePicker!
        @IBOutlet weak var receiptImageView: UIImageView!
        @IBOutlet weak var saveButton: UIBarButtonItem!

        // MARK: - Properties
        /// If `expenseToEdit` is provided, the screen operates in EDIT mode; otherwise, it operates in ADD mode.
        var expenseToEdit: Expense?

        private let categories = ExpenseCategory.names
        private var selectedCategory: String = "General"
        private var isShowingCategoryFallback = false
        private var selectedReceiptImage: UIImage?
        private var receiptImageBase64: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            populateDataIfEditing()
            configureTableLayout()
            registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
                (self: Self, _: UITraitCollection) in
                self.refreshAdaptiveControls()
            }
        }

        // MARK: - UI Setup
        private func setupUI() {
            title = expenseToEdit != nil ? "Edit Expense" : "Add Expense"
            
            let defaultCat = UserDefaults.standard.string(forKey: "defaultCategory") ?? "General"
            selectedCategory = expenseToEdit?.category ?? defaultCat
            updateCategoryButtonTitle()

            configureTextFields()
            configureCategoryMenu()
            setupReceiptImageView()
            setupNavigationItems()
            setupAmountTextField()
            tableView.visibleCells.forEach { FormControlStyler.applyCellStyle(to: $0) }

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
    
        private func configureTextFields() {
            FormTextFieldStyler.apply(to: [amountTextField, titleTextField, notesTextField])
            amountTextField.keyboardType = .decimalPad
            [amountTextField, titleTextField, notesTextField].forEach { textField in
                if let textField = textField, let contentView = textField.superview {
                    FormTextFieldStyler.constrain(textField, in: contentView)
                }
            }
        }
    
        private func configureCategoryMenu() {
            let categoryActions = categories.map { category in
                UIAction(title: category, state: category == selectedCategory ? .on : .off) { [weak self] _ in
                    self?.selectedCategory = category
                    self?.updateCategoryButtonTitle()
                    self?.configureCategoryMenu()
                    self?.updateReceiptPlaceholderIfNeeded()
                }
            }
            categoryButton.menu = UIMenu(title: "Select Category", children: categoryActions)
            categoryButton.showsMenuAsPrimaryAction = true
            FormControlStyler.styleMenuButton(categoryButton, title: selectedCategory)
            if let contentView = categoryButton.superview {
                FormControlStyler.constrainButton(categoryButton, in: contentView)
            }
        }

        private func populateDataIfEditing() {
            guard let expense = expenseToEdit else { return }
            titleTextField.text = expense.title
            let convertedAmount = CurrencyConverter.convertedAmount(fromUSD: expense.amount)
            amountTextField.text = String(format: "%.2f", convertedAmount)
            notesTextField.text = expense.notes
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
            let notesText = notesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            saveButton.isEnabled = false

            let expenseData: [String: Any] = [
                "title": titleText,
                "amount": amountInUSD,
                "baseCurrencyCode": "USD",
                "entryCurrencyCode": CurrencyConverter.code(from: selectedCurrency),
                "category": selectedCategory,
                "date": Timestamp(date: datePicker.date),
                "notes": notesText,
                "createdByUserID": uid,
                "ownerEmail": ExpenseStore.currentOwnerEmail ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ]
            saveButton.title = expenseToEdit == nil ? "Saving..." : "Updating..."
            
            prepareReceiptFields(in: expenseData) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    
                    switch result {
                    case .success(let preparedExpenseData):
                        if let expense = self.expenseToEdit {
                            ExpenseStore.updateExpense(id: expense.id, data: preparedExpenseData) { [weak self] error in
                                DispatchQueue.main.async {
                                    self?.saveButton.isEnabled = true
                                    self?.saveButton.title = "Update"
                                    if let error = error {
                                        self?.showAlert(title: "Update Error", message: error.localizedDescription)
                                    } else {
                                        self?.showSuccessAndReturnToExpenses(title: "Expense Updated", message: "Your expense was updated successfully.")
                                    }
                                }
                            }
                        } else {
                            ExpenseStore.addExpense(preparedExpenseData) { [weak self] error in
                                DispatchQueue.main.async {
                                    self?.saveButton.isEnabled = true
                                    self?.saveButton.title = "Save"
                                    if let error = error {
                                        self?.showAlert(title: "Save Error", message: error.localizedDescription)
                                    } else {
                                        self?.showSuccessAndReturnToExpenses(title: "Expense Added", message: "Your expense was saved successfully.")
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        self.saveButton.isEnabled = true
                        self.saveButton.title = self.expenseToEdit == nil ? "Save" : "Update"
                        self.showAlert(title: "Receipt Upload Error", message: error.localizedDescription)
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
            updateReceiptPlaceholderIfNeeded()
            receiptImageView.tintColor = nil
            receiptImageView.contentMode = .scaleAspectFill
            receiptImageView.clipsToBounds = true
            receiptImageView.layer.cornerRadius = 8
            receiptImageView.isUserInteractionEnabled = true
            configureResponsiveReceiptImageView()
            receiptImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(receiptImageTapped)))
        }
    
        private func configureResponsiveReceiptImageView() {
            guard let contentView = receiptImageView.superview else { return }
            receiptImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
                constraint.firstItem === receiptImageView || constraint.secondItem === receiptImageView
            })
            
            NSLayoutConstraint.activate([
                receiptImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                receiptImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
                receiptImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                receiptImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
                receiptImageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
                receiptImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 680),
                receiptImageView.heightAnchor.constraint(equalTo: receiptImageView.widthAnchor, multiplier: 9.0 / 16.0)
            ])
        }
    
        private func updateReceiptPlaceholderIfNeeded() {
            guard selectedReceiptImage == nil else { return }
            guard isShowingCategoryFallback || expenseToEdit?.hasReceiptImage != true else { return }
            isShowingCategoryFallback = true
            receiptImageView?.image = CategoryImageProvider.image(
                for: selectedCategory,
                size: CGSize(width: 640, height: 360),
                traitCollection: traitCollection
            )
        }
    
        private func setReceiptImage(for expense: Expense) {
            if let image = image(fromBase64: expense.receiptImageBase64) {
                isShowingCategoryFallback = false
                receiptImageView.image = image
                return
            }
            
            guard let urlString = expense.receiptImageURL,
                  let url = URL(string: urlString) else {
                isShowingCategoryFallback = true
                receiptImageView.image = CategoryImageProvider.image(
                    for: expense.category,
                    size: CGSize(width: 640, height: 360),
                    traitCollection: traitCollection
                )
                return
            }
            
            isShowingCategoryFallback = false
            receiptImageView.image = UIImage(systemName: "photo")
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    guard self?.selectedReceiptImage == nil else { return }
                    self?.receiptImageView.image = image
                }
            }.resume()
        }
    
        private func refreshAdaptiveControls() {
            configureTextFields()
            FormControlStyler.styleMenuButton(categoryButton, title: selectedCategory)
            updateReceiptPlaceholderIfNeeded()
            tableView.visibleCells.forEach { FormControlStyler.applyCellStyle(to: $0) }
        }
    
        @objc private func receiptImageTapped() {
            let alert = UIAlertController(title: "Receipt Photo", message: nil, preferredStyle: .actionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                    self?.presentImagePicker(sourceType: .camera)
                })
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                alert.addAction(UIAlertAction(title: "Choose from Gallery", style: .default) { [weak self] _ in
                    self?.presentImagePicker(sourceType: .photoLibrary)
                })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.sourceView = receiptImageView
            alert.popoverPresentationController?.sourceRect = receiptImageView.bounds
            present(alert, animated: true)
        }
    
        private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            picker.allowsEditing = false
            present(picker, animated: true)
        }
    
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            
            guard let image = info[.originalImage] as? UIImage else { return }
            selectedReceiptImage = image
            receiptImageBase64 = nil
            isShowingCategoryFallback = false
            receiptImageView.image = image
            receiptImageView.contentMode = .scaleAspectFill
        }
    
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    
        private func prepareReceiptFields(
            in expenseData: [String: Any],
            completion: @escaping (Result<[String: Any], Error>) -> Void
        ) {
            var preparedExpenseData = expenseData
            
            guard let selectedReceiptImage else {
                if let receiptImageURL = expenseToEdit?.receiptImageURL, !receiptImageURL.isEmpty {
                    preparedExpenseData["receiptImageURL"] = receiptImageURL
                }
                if let receiptImageBase64 = expenseToEdit?.receiptImageBase64, !receiptImageBase64.isEmpty {
                    preparedExpenseData["receiptImageBase64"] = receiptImageBase64
                }
                completion(.success(preparedExpenseData))
                return
            }
            
            guard CloudinaryUploader.isConfigured else {
                receiptImageBase64 = base64ReceiptString(from: selectedReceiptImage)
                if let receiptImageBase64, !receiptImageBase64.isEmpty {
                    preparedExpenseData["receiptImageBase64"] = receiptImageBase64
                }
                preparedExpenseData["receiptImageURL"] = FieldValue.delete()
                completion(.success(preparedExpenseData))
                return
            }
            
            CloudinaryUploader.uploadReceiptImage(selectedReceiptImage) { result in
                switch result {
                case .success(let receiptURL):
                    preparedExpenseData["receiptImageURL"] = receiptURL
                    preparedExpenseData["receiptImageBase64"] = FieldValue.delete()
                    completion(.success(preparedExpenseData))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
        private func base64ReceiptString(from image: UIImage) -> String? {
            let encodedImage = resizedImage(image, maxDimension: 480)
                .jpegData(compressionQuality: 0.45)?
                .base64EncodedString()
            guard let encodedImage, encodedImage.utf8.count < 900_000 else { return nil }
            return encodedImage
        }
    
        private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let largestSide = max(image.size.width, image.size.height)
            guard largestSide > maxDimension else { return image }
            
            let scale = maxDimension / largestSide
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
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
    
        override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            switch indexPath.row {
            case 0, 1, 2:
                return FormTextFieldStyler.rowHeight
            case 3:
                return FormControlStyler.controlHeight + 20
            case 5:
                return preferredImageRowHeight(for: tableView.bounds.width)
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
    
        override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            FormControlStyler.applyCellStyle(to: cell)
        }
    
        private func preferredImageRowHeight(for width: CGFloat) -> CGFloat {
            let horizontalPadding: CGFloat = 40
            let imageWidth = max(0, min(width - horizontalPadding, 680))
            return min(max(imageWidth * 9 / 16 + 20, 176), 404)
        }
}
