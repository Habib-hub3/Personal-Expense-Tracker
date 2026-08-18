//
//  RegisterViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
            (self: Self, _: UITraitCollection) in
            self.refreshTextFieldAppearance()
        }
    }
    
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        FormTextFieldStyler.apply(to: [
            usernameTextField,
            firstNameTextField,
            lastNameTextField,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField
        ])
        setupResponsiveLayout()
    }
   
    private func setupResponsiveLayout() {
        guard let formView = usernameTextField.superview else { return }
        let navigationBar = view.subviews.compactMap { $0 as? UINavigationBar }.first
        let labels = Dictionary(uniqueKeysWithValues: formView.subviews.compactMap { subview -> (String, UILabel)? in
            guard let label = subview as? UILabel, let text = label.text else { return nil }
            return (text, label)
        })
        
        let orderedRows: [(UILabel?, UITextField)] = [
            (labels["Username:"], usernameTextField),
            (labels["First Name:"], firstNameTextField),
            (labels["Last Name:"], lastNameTextField),
            (labels["Email:"], emailTextField),
            (labels["Password:"], passwordTextField),
            (labels["Confirm Password:"], confirmPasswordTextField)
        ]
        
        ([formView, navigationBar, doneButton] + orderedRows.flatMap { [$0.0, $0.1] }).forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            constraint.firstItem === formView || constraint.secondItem === formView ||
            constraint.firstItem === navigationBar || constraint.secondItem === navigationBar
        })
        NSLayoutConstraint.deactivate(formView.constraints)
        orderedRows.forEach { label, field in
            if let label = label {
                NSLayoutConstraint.deactivate(label.constraints)
            }
            NSLayoutConstraint.deactivate(field.constraints)
        }
        NSLayoutConstraint.deactivate(doneButton.constraints)
        
        let safeArea = view.safeAreaLayoutGuide
        let isCompactWidth = view.bounds.width < 390
        let labelColumnWidth: CGFloat = isCompactWidth ? 128 : 144
        let formWidthConstraint = formView.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.9)
        formWidthConstraint.priority = .defaultHigh
        let centerYConstraint = formView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 12)
        centerYConstraint.priority = .defaultHigh
        
        var constraints: [NSLayoutConstraint] = [
            formView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            formView.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 16),
            formView.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -16),
            formWidthConstraint,
            formView.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            formView.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -24),
            centerYConstraint,
            
            doneButton.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
            doneButton.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            formView.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor)
        ]
        
        if let navigationBar = navigationBar {
            constraints.append(contentsOf: [
                navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
                navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationBar.bottomAnchor.constraint(equalTo: safeArea.topAnchor, constant: 54),
                formView.topAnchor.constraint(greaterThanOrEqualTo: navigationBar.bottomAnchor, constant: 24)
            ])
        } else {
            constraints.append(formView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 32))
        }
        
        var previousField: UITextField?
        for (label, field) in orderedRows {
            constraints.append(contentsOf: [
                field.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
                field.heightAnchor.constraint(equalToConstant: FormTextFieldStyler.fieldHeight)
            ])
            
            if let label = label {
                label.setContentCompressionResistancePriority(.required, for: .horizontal)
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.85
                label.numberOfLines = 1
                constraints.append(contentsOf: [
                    label.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
                    label.centerYAnchor.constraint(equalTo: field.centerYAnchor),
                    label.widthAnchor.constraint(equalToConstant: labelColumnWidth),
                    field.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
                    field.widthAnchor.constraint(greaterThanOrEqualToConstant: 130)
                ])
            } else {
                constraints.append(field.leadingAnchor.constraint(equalTo: formView.leadingAnchor))
            }
            
            if let previousField = previousField {
                constraints.append(field.topAnchor.constraint(equalTo: previousField.bottomAnchor, constant: 12))
            } else {
                constraints.append(field.topAnchor.constraint(equalTo: formView.topAnchor))
            }
            previousField = field
        }
        
        if let lastField = previousField {
            constraints.append(doneButton.topAnchor.constraint(equalTo: lastField.bottomAnchor, constant: 24))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func refreshTextFieldAppearance() {
        FormTextFieldStyler.apply(to: [
            usernameTextField,
            firstNameTextField,
            lastNameTextField,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField
        ])
    }
    
    // MARK: - IBActions
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !username.isEmpty,
              let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty,
              let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty,
              let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Passwords do not match", message: "Please try again.")
            return
        }
        
        doneButton.isEnabled = false
        createAccount(
            username: username,
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
    }

    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        returnToLoginPage()
    }

    // MARK: - Helper Methods
    private func createAccount(username: String, firstName: String, lastName: String, email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.doneButton.isEnabled = true
                    self?.showAlert(title: "Registration Error", message: error.localizedDescription)
                }
                return
            }
            
            guard let authUser = authResult?.user else {
                DispatchQueue.main.async {
                    self?.doneButton.isEnabled = true
                    self?.showAlert(title: "Registration Error", message: "Unable to create the account.")
                }
                return
            }
            
            let uid = authUser.uid
            let displayNameChangeRequest = authUser.createProfileChangeRequest()
            displayNameChangeRequest.displayName = "\(firstName) \(lastName)"
            displayNameChangeRequest.commitChanges()
            
            DataManager.shared.reserveUsername(username, uid: uid, email: email) { [weak self] result in
                switch result {
                case .success:
                    let newUser = User(uid: uid, email: email, username: username, firstName: firstName, lastName: lastName)
                    DataManager.shared.saveUserProfile(user: newUser) { success in
                        if !success {
                            print("User created, but failed to save profile data.")
                        }
                        
                        DispatchQueue.main.async {
                            self?.showRegistrationSuccessAlert()
                        }
                    }
                case .failure(let error):
                    authUser.delete()
                    DispatchQueue.main.async {
                        self?.doneButton.isEnabled = true
                        self?.showAlert(
                            title: self?.usernameReservationErrorTitle(for: error) ?? "Registration Error",
                            message: self?.usernameReservationErrorMessage(for: error) ?? error.localizedDescription
                        )
                    }
                }
            }
        }
    }
    
    private func usernameReservationErrorTitle(for error: Error) -> String {
        if isMissingFirestoreDatabaseError(error) {
            return "Firestore Not Set Up"
        }
        if isPermissionError(error) {
            return "Firestore Rules Blocked"
        }
        if isOfflineError(error) {
            return "Internet Required"
        }
        if error.localizedDescription.localizedCaseInsensitiveContains("taken") {
            return "Username Taken"
        }
        return "Registration Error"
    }
    
    private func usernameReservationErrorMessage(for error: Error) -> String {
        if isMissingFirestoreDatabaseError(error) {
            return "Create the default Cloud Firestore database for this Firebase project, then try registering again. Expenses, settings sync, and Summary all need Firestore."
        }
        if isPermissionError(error) {
            return "Update your Cloud Firestore rules to allow signed-in users to create username reservations and profile data."
        }
        if isOfflineError(error) {
            return "Connect to the internet and try registering again so the app can reserve your unique username."
        }
        if error.localizedDescription.localizedCaseInsensitiveContains("taken") {
            return "Please choose another username."
        }
        return error.localizedDescription
    }
    
    private func isMissingFirestoreDatabaseError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("database") && message.contains("does not exist")
    }
    
    private func isPermissionError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("permission") || message.contains("denied")
    }
    
    private func isOfflineError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("offline") || message.contains("network") || message.contains("internet")
    }
    
    private func showRegistrationSuccessAlert() {
        let alert = UIAlertController(
            title: "Account Created",
            message: "Your account has been successfully registered. Press OK to return to Login and sign in with your new account.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            try? Auth.auth().signOut()
            self?.returnToLoginPage()
        })
        present(alert, animated: true)
    }
    
    private func returnToLoginPage() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            let storyboard = UIStoryboard(name: "PersonalExpensesTracker", bundle: nil)
            guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = loginVC
                window.makeKeyAndVisible()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
