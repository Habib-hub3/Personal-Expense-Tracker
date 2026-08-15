//
//  SettingsTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 15/08/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

class SettingsTableViewController: UITableViewController {
    
    // MARK: - IBOutleets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var defaultCategoryButton: UIButton!
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var dailyRemindersSwitch: UISwitch!
    @IBOutlet weak var reminderDatePicker: UIDatePicker!
    
    @IBOutlet weak var clearDataButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    // MARK: - Properties
    private let currencies = ["USD ($), EUR(€)", "BHD (BD)","GBP(£)"]
    private let categories = ["Food", "Transport", "Entertainment", "General", "Shopping"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenus()
        loadUserData()
        loadSavedSettings()
            }

    // MARK: - UI Setup
    private func setupUI() {
        // Round profile image
        if let profileImageView = profileImageView {
            profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
            profileImageView.clipsToBounds = true
        }
    }
    
    private func setupMenus() {
        // Currency Dropdown Menu
        let currencyActions = currencies.map {
            currency in UIAction(title: currency) { [weak self] _ in
                self?.currencyButton.setTitle(currency, for: .normal)
                UserDefaults.standard.set(currency, forKey: "appCurrency")
            }
        }
        currencyButton?.menu = UIMenu(title: "Select Currency", children: currencyActions)
        currencyButton?.showsMenuAsPrimaryAction = true
        
        //Category Dropdown Menu
        let categoryActions = categories.map {
            category in UIAction(title: category) { [weak self] _ in
                self?.defaultCategoryButton.setTitle(category, for: .normal)
                UserDefaults.standard.set(category, forKey: "defaultCategory")
            }
        }
        defaultCategoryButton?.menu = UIMenu(title: "Select Category", children: categoryActions)
        defaultCategoryButton?.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Load User Data & Prefrences
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            userNameLabel.text = user.displayName ?? "User Name"
            userEmailLabel.text = user.email ?? "No Email"
            
            // Fetch profile data from Firestore
            Firestore.firestore().collection("users").document(user.uid).getDocument { [weak self] snapshot,  _ in
                if let data = snapshot?.data(), let username = data["username"] as? String {
                    self?.userNameLabel.text = username
                }
            }
        }
    }
    
    private func loadSavedSettings(){
        // Dark Mode
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        darkModeSwitch?.isOn = isDarkMode
        
        // Currency & category
        if let currency = UserDefaults.standard.string(forKey: "appCurrency"){
            currencyButton?.setTitle(currency, for: .normal)
        }
        if let category = UserDefaults.standard.string(forKey: "defaultCategory"){
            defaultCategoryButton?.setTitle(category, for: .normal)
        }
        
        // Reminders
        let isReminderOn = UserDefaults.standard.bool(forKey: "dailyReminders")
        dailyRemindersSwitch?.isOn = isReminderOn
        reminderDatePicker?.isEnabled = isReminderOn
    }
    
    // MARK: - Actions
    
    @IBAction func darkModeToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isDarkMode")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = sender.isOn ? .dark : .light
            }
        }
    }
    
    @IBAction func dailyRemindersToggled(_ sender: UISwitch) {
        reminderDatePicker?.isEnabled = sender.isOn
        UserDefaults.standard.set(sender.isOn, forKey: "dailyReminders")
        
        if sender.isOn {
            requestNotificationPermission()
        }else{
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyExpenseReminder"])
        }
    }
    
    @IBAction func reminderTimeChanged(_ sender: UIDatePicker) {
        if dailyRemindersSwitch.isOn {
            scheduleDailyNotification(at: sender.date)
        }
    }
    
    @IBAction func clearAllDataTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: "This will delete all your data, and cannot be undone",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Clear Data", style: .destructive) { [weak self] _ in
            self?.performDataDeletion()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Log Out" , message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive){ [weak self] _ in
            do {
                try Auth.auth().signOut()
                self?.redirectToLogin()
            } catch {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - Table View Delegate
        // Allows tapping non-button cells directly if needed
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        // MARK: - Helper Methods

        private func performDataDeletion() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            
            db.collection("users").document(uid).collection("expenses").getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                for doc in documents {
                    doc.reference.delete()
                }
                self?.showAlert(title: "Success", message: "All expense data has been cleared.")
            }
        }

        private func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self.scheduleDailyNotification(at: self.reminderDatePicker.date)
                    } else {
                        self.dailyRemindersSwitch.isOn = false
                        self.reminderDatePicker.isEnabled = false
                        self.showAlert(title: "Permission Denied", message: "Enable notifications in iOS Settings to enable reminders.")
                    }
                }
            }
        }

        private func scheduleDailyNotification(at date: Date) {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["dailyExpenseReminder"])

            let content = UNMutableNotificationContent()
            content.title = "Expense Tracker"
            content.body = "Don't forget to log your daily expenses!"
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyExpenseReminder", content: content, trigger: trigger)

            center.add(request)
        }

        private func redirectToLogin() {
            let storyboard = UIStoryboard(name: "PersonalExpensesTracker", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                loginVC.modalPresentationStyle = .fullScreen
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                } else {
                    present(loginVC, animated: true)
                }
            }
        }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}
