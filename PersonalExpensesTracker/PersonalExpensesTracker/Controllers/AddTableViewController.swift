//
//  AddTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    // MARK: - IBOutlets
        @IBOutlet weak var titleTextField: UITextField!
        @IBOutlet weak var amountTextField: UITextField!
        @IBOutlet weak var categoryButton: UIButton!
        @IBOutlet weak var datePicker: UIDatePicker!
        @IBOutlet weak var receiptImageView: UIImageView!
        @IBOutlet weak var saveButton: UIBarButtonItem!

        // MARK: - Properties
        private let categories = ExpenseCategory.names
        private var selectedCategory: String = "General"
        private var selectedReceiptImage: UIImage?
        private var receiptImageBase64: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            configureTableLayout()
            observeSharedSettingsChanges()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        private func setupUI() {
            title = "Add(+)"
            
            // Load user preference or default category
            let defaultCat = UserDefaults.standard.string(forKey: "defaultCategory") ?? "General"
            selectedCategory = defaultCat
            categoryButton.setTitle(selectedCategory, for: .normal)

            configureCategoryMenu()
            setupReceiptImageView()
            setupNavigationItems()
            setupFormValidation()
        }
    
        private func configureCategoryMenu() {
            let categoryActions = categories.map { category in
                UIAction(title: category, state: category == selectedCategory ? .on : .off) { [weak self] _ in
                    self?.selectedCategory = category
                    self?.categoryButton.setTitle(category, for: .normal)
                    self?.configureCategoryMenu()
                    self?.updateSaveButtonState()
                }
            }
            categoryButton.menu = UIMenu(title: "Select Category", children: categoryActions)
            categoryButton.showsMenuAsPrimaryAction = true
        }
    
        private func setupNavigationItems() {
            let saveItem = saveButton ?? UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
            saveItem.title = "Save"
            saveItem.style = .done
            saveItem.target = self
            saveItem.action = #selector(saveButtonTapped(_:))
            saveItem.isEnabled = false
            saveItem.tintColor = .systemBlue
            saveButton = saveItem
            navigationItem.rightBarButtonItem = saveItem
            navigationItem.leftBarButtonItem = nil
        }

        // MARK: - IBActions
        @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
            guard let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !titleText.isEmpty,
                  let amountText = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let amount = Double(amountText), amount > 0,
                  !selectedCategory.isEmpty else {
                updateSaveButtonState()
                showAlert(title: "Missing Information", message: "Please fill in the title, amount, category, and date.")
                return
            }

            guard let uid = Auth.auth().currentUser?.uid else {
                showAlert(title: "Error", message: "User not authenticated.")
                return
            }
            
            let selectedCurrency = CurrencyConverter.selectedCurrencyDisplayName
            let amountInUSD = CurrencyConverter.usdAmount(from: amount, currencyDisplayName: selectedCurrency)
            saveButton.isEnabled = false
            saveButton.title = "Saving..."

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
            
            uploadReceiptIfNeeded { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let receiptURL):
                        if let receiptURL = receiptURL {
                            expenseData["receiptImageURL"] = receiptURL
                        }
                        if let receiptImageBase64 = self.receiptImageBase64, !receiptImageBase64.isEmpty {
                            expenseData["receiptImageBase64"] = receiptImageBase64
                        }
                        self.saveExpense(expenseData)
                    case .failure(let error):
                        self.saveButton.title = "Save"
                        self.updateSaveButtonState()
                        self.showAlert(title: "Receipt Upload Error", message: error.localizedDescription)
                    }
                }
            }
        }

        private func uploadReceiptIfNeeded(completion: @escaping (Result<String?, Error>) -> Void) {
            guard let selectedReceiptImage = selectedReceiptImage else {
                completion(.success(nil))
                return
            }

            guard CloudinaryUploader.isConfigured else {
                receiptImageBase64 = base64ReceiptString(from: selectedReceiptImage)
                completion(.success(nil))
                return
            }
            
            CloudinaryUploader.uploadReceiptImage(selectedReceiptImage) { result in
                switch result {
                case .success(let receiptURL):
                    completion(.success(receiptURL))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
        private func saveExpense(_ expenseData: [String: Any]) {
            ExpenseStore.addExpense(expenseData) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.saveButton.title = "Save"
                    
                    if let error = error {
                        self.updateSaveButtonState()
                        self.showAlert(title: "Save Error", message: error.localizedDescription)
                    } else {
                        self.showSuccessAndReturnToExpenses()
                    }
                }
            }
        }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            presentAlert(alert)
        }
    
        private func showSuccessAndReturnToExpenses() {
            let alert = UIAlertController(
                title: "Expense Saved",
                message: "Your expense has been added successfully.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.resetForm()
                self?.returnToExpensesScene()
            })
            presentAlert(alert)
        }
    
        private func presentAlert(_ alert: UIAlertController) {
            let presenter = navigationController?.topViewController ?? self
            if let presentedViewController = presenter.presentedViewController {
                presentedViewController.dismiss(animated: false) {
                    presenter.present(alert, animated: true)
                }
            } else {
                presenter.present(alert, animated: true)
            }
        }
    
        private func returnToExpensesScene() {
            guard let tabBarController = tabBarController else { return }
            tabBarController.selectedIndex = 0
            
            if let expensesNavigationController = tabBarController.selectedViewController as? UINavigationController {
                expensesNavigationController.popToRootViewController(animated: false)
            }
        }
    
        private func resetForm() {
            titleTextField.text = nil
            amountTextField.text = nil
            datePicker.date = Date()
            selectedReceiptImage = nil
            receiptImageBase64 = nil
            receiptImageView.image = UIImage(systemName: "photo")
            applyDefaultCategoryIfFormIsEmpty()
            updateSaveButtonState()
        }
    
        private func setupFormValidation() {
            amountTextField.keyboardType = .decimalPad
            amountTextField.delegate = self
            titleTextField.addTarget(self, action: #selector(formFieldChanged), for: .editingChanged)
            amountTextField.addTarget(self, action: #selector(formFieldChanged), for: .editingChanged)
            datePicker.addTarget(self, action: #selector(formFieldChanged), for: .valueChanged)
            updateSaveButtonState()
        }
    
        @objc private func formFieldChanged() {
            updateSaveButtonState()
        }
    
        private func updateSaveButtonState() {
            saveButton?.isEnabled = isFormComplete
        }
    
        private var isFormComplete: Bool {
            let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let amountText = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let amount = Double(amountText) ?? 0
            return !titleText.isEmpty && amount > 0 && !selectedCategory.isEmpty
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
            applyDefaultCategoryIfFormIsEmpty()
        }
    
        private func applyDefaultCategoryIfFormIsEmpty() {
            let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let amountText = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard titleText.isEmpty, amountText.isEmpty, receiptImageBase64 == nil else { return }
            
            let defaultCategory = UserDefaults.standard.string(forKey: "defaultCategory") ?? "General"
            selectedCategory = defaultCategory
            categoryButton.setTitle(defaultCategory, for: .normal)
            configureCategoryMenu()
        }
    
        private func setupReceiptImageView() {
            receiptImageView.image = UIImage(systemName: "photo")
            receiptImageView.tintColor = .secondaryLabel
            receiptImageView.contentMode = .scaleAspectFit
            receiptImageView.isUserInteractionEnabled = true
            receiptImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(receiptImageTapped)))
        }
    
        @objc private func receiptImageTapped() {
            let alert = UIAlertController(title: "Receipt Photo", message: nil, preferredStyle: .actionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                    self?.presentImagePicker(sourceType: .camera)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Choose from Gallery", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            })
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
            receiptImageView.image = image
            selectedReceiptImage = image
            receiptImageBase64 = nil
            updateSaveButtonState()
        }
    
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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
