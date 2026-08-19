//
//  LoginViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    // MARK: - State
    
    private var shouldPerformLoginSegue = false
    private weak var logoImageView: UIImageView?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
            (self: Self, _: UITraitCollection) in
            self.refreshAdaptiveAppearance()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
        FormTextFieldStyler.apply(to: [emailTextField, passwordTextField])
        [emailTextField, passwordTextField].forEach { $0?.autocorrectionType = .no }
        logInButton.layer.cornerRadius = 8
        signUpButton.titleLabel?.adjustsFontSizeToFitWidth = true
        signUpButton.titleLabel?.minimumScaleFactor = 0.8
        setupResponsiveLayout()
    }
    
    // Rebuilds storyboard constraints so the login form scales across compact and regular screens.
    private func setupResponsiveLayout() {
        guard let formView = emailTextField.superview,
              let logoImageView = view.subviews.compactMap({ $0 as? UIImageView }).first else { return }
        
        self.logoImageView = logoImageView
        configureLogoAppearance(for: logoImageView)
        
        [formView, logoImageView, emailTextField, passwordTextField, logInButton, signUpButton].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let signUpLabel = formView.subviews.compactMap { $0 as? UILabel }.first
        signUpLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            constraint.firstItem === formView || constraint.secondItem === formView ||
            constraint.firstItem === logoImageView || constraint.secondItem === logoImageView
        })
        NSLayoutConstraint.deactivate(formView.constraints)
        [emailTextField, passwordTextField, logInButton, signUpButton, signUpLabel].forEach {
            if let view = $0 {
                NSLayoutConstraint.deactivate(view.constraints)
            }
        }
        
        let safeArea = view.safeAreaLayoutGuide
        let contentGuide = UILayoutGuide()
        view.addLayoutGuide(contentGuide)
        
        let logoWidthConstraint = logoImageView.widthAnchor.constraint(equalToConstant: 220)
        logoWidthConstraint.priority = .defaultHigh
        let formWidthConstraint = formView.widthAnchor.constraint(equalTo: contentGuide.widthAnchor)
        formWidthConstraint.priority = .defaultHigh
        
        var constraints: [NSLayoutConstraint] = [
            contentGuide.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: -24),
            contentGuide.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 32),
            contentGuide.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -32),
            contentGuide.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 24),
            contentGuide.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -24),
            
            logoImageView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: contentGuide.centerXAnchor),
            logoWidthConstraint,
            logoImageView.widthAnchor.constraint(lessThanOrEqualTo: contentGuide.widthAnchor, multiplier: 0.5),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
            
            formView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 28),
            formView.centerXAnchor.constraint(equalTo: contentGuide.centerXAnchor),
            formView.leadingAnchor.constraint(greaterThanOrEqualTo: contentGuide.leadingAnchor),
            formView.trailingAnchor.constraint(lessThanOrEqualTo: contentGuide.trailingAnchor),
            formWidthConstraint,
            formView.widthAnchor.constraint(lessThanOrEqualToConstant: 460),
            formView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            
            emailTextField.topAnchor.constraint(equalTo: formView.topAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: FormTextFieldStyler.fieldHeight),
            
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 12),
            passwordTextField.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: FormTextFieldStyler.fieldHeight),
            
            logInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            logInButton.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
            logInButton.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
            logInButton.heightAnchor.constraint(equalToConstant: 44),
            
            signUpButton.trailingAnchor.constraint(lessThanOrEqualTo: formView.trailingAnchor),
            signUpButton.centerYAnchor.constraint(equalTo: signUpLabel?.centerYAnchor ?? formView.bottomAnchor),
            formView.bottomAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 12)
        ]
        
        if let signUpLabel = signUpLabel {
            constraints.append(contentsOf: [
                signUpLabel.topAnchor.constraint(equalTo: logInButton.bottomAnchor, constant: 16),
                signUpLabel.leadingAnchor.constraint(greaterThanOrEqualTo: formView.leadingAnchor),
                signUpButton.leadingAnchor.constraint(equalTo: signUpLabel.trailingAnchor, constant: 8),
                signUpButton.firstBaselineAnchor.constraint(equalTo: signUpLabel.firstBaselineAnchor),
                signUpLabel.centerXAnchor.constraint(equalTo: formView.centerXAnchor, constant: -42)
            ])
        } else {
            constraints.append(signUpButton.topAnchor.constraint(equalTo: logInButton.bottomAnchor, constant: 16))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func refreshAdaptiveAppearance() {
        FormTextFieldStyler.apply(to: [emailTextField, passwordTextField])
        if let logoImageView {
            configureLogoAppearance(for: logoImageView)
        }
    }
    
    private func configureLogoAppearance(for logoImageView: UIImageView) {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        logoImageView.image = UIImage(named: "AppLogo")
        logoImageView.backgroundColor = isDarkMode ? .secondarySystemBackground : .clear
        logoImageView.layer.cornerRadius = 24
        logoImageView.layer.borderWidth = isDarkMode ? 1 : 0
        logoImageView.layer.borderColor = UIColor.separator.resolvedColor(with: logoImageView.traitCollection).cgColor
        logoImageView.clipsToBounds = true
    }
    
    // MARK: - Actions
    
    @IBAction func logInButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
                showAlert(title: "Error", message: "Please fill all the fields")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Login Failed", message: self?.loginErrorMessage(from: error) ?? error.localizedDescription)
                    return
                }
                
                self?.loadSharedSettingsThenNavigate(email: email)
            }
        }
        
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        // Navigation to RegisterViewController is handled by the storyboard segue.
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "loginToMainTabBar" {
            return shouldPerformLoginSegue
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginToMainTabBar",
           let tabBarVC = segue.destination as? UITabBarController {
            tabBarVC.selectedIndex = 0
        }
    }
    
    private func navigateToMainApp() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        shouldPerformLoginSegue = true
        performSegue(withIdentifier: "loginToMainTabBar", sender: self)
        shouldPerformLoginSegue = false
        AppearanceManager.applySavedAppearance()
        SharedSettingsStore.startListeningForCurrentUser()
    }
    
    // MARK: - Settings Sync
    
    private func loadSharedSettingsThenNavigate(email: String) {
        Firestore.firestore()
            .collection("accountSettings")
            .document(accountSettingsDocumentID(for: email))
            .getDocument { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    if let data = snapshot?.data() {
                        self?.applySharedSettings(data)
                    } else {
                        AppearanceManager.applySavedAppearance()
                    }
                    self?.navigateToMainApp()
                }
            }
    }
    
    private func applySharedSettings(_ data: [String: Any]) {
        SharedSettingsStore.apply(data)
    }
    
    // MARK: - Helpers
    
    private func accountSettingsDocumentID(for email: String) -> String {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return Data(normalizedEmail.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
            return nil
        }
        return trimmedValue
    }
    
    private func loginErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        return "\(error.localizedDescription)\n\nFirebase error code: \(nsError.code)"
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
