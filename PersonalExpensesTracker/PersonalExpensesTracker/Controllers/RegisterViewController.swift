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
    }
    
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
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
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Detailed Firebase Auth Error: \(error)")
                self?.showAlert(title: "Registration Error", message: error.localizedDescription)
                return
            }
            
            guard let uid = authResult?.user.uid else { return }
            
            let newUser = User(uid: uid, email: email, username: username)
            DataManager.shared.saveUserProfile(user: newUser) { success in
                if success {
                    self?.showRegistrationSuccessAlert()
                } else {
                    self?.showAlert(title: "Error", message: "User created, but failed to save profile data.")
                }
            }
        }
    }

    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        returnToLoginPage()
    }

    // MARK: - Helper Methods
    private func showRegistrationSuccessAlert() {
        let alert = UIAlertController(
            title: "Registration Successful",
            message: "Your email has been successfully registered.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
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
