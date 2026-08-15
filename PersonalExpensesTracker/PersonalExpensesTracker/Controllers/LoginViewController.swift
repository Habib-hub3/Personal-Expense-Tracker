//
//  LoginViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 11/08/2026.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    private var shouldPerformLoginSegue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
    }
    
    //MARK: - IBActions
    @IBAction func logInButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
                showAlert(title: "Error", message: "Please fill all the fields")
            return
        }
        
        //Firebase Authintication Sign In
        Auth.auth().signIn(withEmail: email, password: password){ [weak self] authResult, error in
            if let error = error{
                self?.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }
            
            // Navigate to Main Tab Bar Controller upon successful login
            self?.navigateToMainApp()
        }
        
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        //Navigate to RegisterViewController is handled via Storyboard Segue
    }
    
    private func navigateToMainApp() {
        guard let tabBarVC = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
        tabBarVC.selectedIndex = 0
        tabBarVC.modalPresentationStyle = .fullScreen
        present(tabBarVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
