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

class SettingsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    private let currencies = ["USD ($)", "EUR (€)", "BHD (BD)", "GBP (£)"]
    private let categories = ExpenseCategory.names
    private var currentUserProfile: User?
    private var sharedSettingsListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenus()
        loadUserData()
        loadSavedSettings()
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) {
            (self: Self, _: UITraitCollection) in
            self.applyControlStyles()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
    }
    
    deinit {
        sharedSettingsListener?.remove()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
    }

    // MARK: - UI Setup
    private func setupUI() {
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.tintColor = .systemGray2
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        setDefaultProfileImage()
        setupResponsiveLayout()
        applyControlStyles()
    }
    
    private func applyControlStyles() {
        FormControlStyler.styleMenuButton(currencyButton)
        FormControlStyler.styleMenuButton(defaultCategoryButton)
        FormControlStyler.styleFilledButton(clearDataButton, title: clearDataButton?.title(for: .normal), color: .systemRed)
        FormControlStyler.styleFilledButton(logoutButton, title: logoutButton?.title(for: .normal), color: .systemRed)
        tableView.visibleCells.forEach { FormControlStyler.applyCellStyle(to: $0) }
    }
    
    private func setupResponsiveLayout() {
        setupProfileLayout()
        setupSettingsRowLayout(control: currencyButton, maximumControlWidth: 220)
        setupSettingsRowLayout(control: defaultCategoryButton, maximumControlWidth: 220)
        setupSettingsRowLayout(control: darkModeSwitch)
        setupSettingsRowLayout(control: dailyRemindersSwitch)
        setupSettingsRowLayout(control: reminderDatePicker, maximumControlWidth: 170)
        setupSettingsCellStacks()
        setupFullWidthButtonLayout(logoutButton)
    }
    
    private func setupProfileLayout() {
        guard let contentView = profileImageView.superview else { return }
        [profileImageView, userNameLabel, userEmailLabel].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.deactivate(contentView.constraints)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 72),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),
            
            userNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            userNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            userNameLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -4),
            
            userEmailLabel.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor),
            userEmailLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            userEmailLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 4)
        ])
    }
    
    private func setupSettingsCellStacks() {
        stackRows(
            [currencyButton.superview, defaultCategoryButton.superview, darkModeSwitch.superview],
            in: currencyButton.superview?.superview,
            rowHeight: 48,
            spacing: 8,
            topPadding: 12,
            bottomPadding: 12
        )
        stackRows(
            [dailyRemindersSwitch.superview, reminderDatePicker.superview, clearDataButton],
            in: dailyRemindersSwitch.superview?.superview,
            rowHeight: 50,
            spacing: 12,
            topPadding: 14,
            bottomPadding: 14
        )
    }
    
    private func stackRows(
        _ rows: [UIView?],
        in contentView: UIView?,
        rowHeight: CGFloat,
        spacing: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat
    ) {
        guard let contentView = contentView else { return }
        let rows = rows.compactMap { $0 }
        guard !rows.isEmpty else { return }
        
        rows.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            rows.contains { row in constraint.firstItem === row || constraint.secondItem === row }
        })
        
        var constraints: [NSLayoutConstraint] = []
        for (index, row) in rows.enumerated() {
            if row === clearDataButton {
                constraints.append(contentsOf: [
                    row.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    row.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: FormControlStyler.horizontalPadding),
                    row.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -FormControlStyler.horizontalPadding),
                    row.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
                    row.heightAnchor.constraint(equalToConstant: FormControlStyler.controlHeight)
                ])
            } else {
                constraints.append(contentsOf: [
                    row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    row.heightAnchor.constraint(equalToConstant: rowHeight)
                ])
            }
            
            if index == 0 {
                constraints.append(row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding))
            } else {
                constraints.append(row.topAnchor.constraint(equalTo: rows[index - 1].bottomAnchor, constant: spacing))
            }
        }
        
        if let lastRow = rows.last {
            constraints.append(lastRow.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -bottomPadding))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupSettingsRowLayout(control: UIView, maximumControlWidth: CGFloat? = nil) {
        guard let rowView = control.superview,
              let label = rowView.subviews.compactMap({ $0 as? UILabel }).first else { return }
        
        [label, control].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.numberOfLines = 1
        if let button = control as? UIButton {
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.75
        }
        if let datePicker = control as? UIDatePicker {
            datePicker.preferredDatePickerStyle = .compact
        }
        NSLayoutConstraint.deactivate(rowView.constraints)
        
        var constraints: [NSLayoutConstraint] = [
            label.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 32),
            label.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -16),
            
            control.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -24),
            control.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            control.topAnchor.constraint(greaterThanOrEqualTo: rowView.topAnchor, constant: 6),
            control.bottomAnchor.constraint(lessThanOrEqualTo: rowView.bottomAnchor, constant: -6)
        ]
        
        if let maximumControlWidth = maximumControlWidth {
            constraints.append(control.widthAnchor.constraint(lessThanOrEqualToConstant: maximumControlWidth))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupFullWidthButtonLayout(_ button: UIButton) {
        guard let contentView = button.superview else { return }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            constraint.firstItem === button || constraint.secondItem === button
        })
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupMenus() {
        // Currency Dropdown Menu
        let currencyActions = currencies.map {
            currency in UIAction(title: currency) { [weak self] _ in
                self?.currencyButton.setTitle(currency, for: .normal)
                FormControlStyler.styleMenuButton(self?.currencyButton, title: currency)
                UserDefaults.standard.set(currency, forKey: "appCurrency")
                self?.saveSharedSettings(["preferredCurrency": currency, "currency": currency])
            }
        }
        currencyButton?.menu = UIMenu(title: "Select Currency", children: currencyActions)
        currencyButton?.showsMenuAsPrimaryAction = true
        FormControlStyler.styleMenuButton(currencyButton)
        
        //Category Dropdown Menu
        let categoryActions = categories.map {
            category in UIAction(title: category) { [weak self] _ in
                self?.defaultCategoryButton.setTitle(category, for: .normal)
                FormControlStyler.styleMenuButton(self?.defaultCategoryButton, title: category)
                UserDefaults.standard.set(category, forKey: "defaultCategory")
                self?.saveSharedSettings(["defaultCategory": category])
            }
        }
        defaultCategoryButton?.menu = UIMenu(title: "Select Category", children: categoryActions)
        defaultCategoryButton?.showsMenuAsPrimaryAction = true
        FormControlStyler.styleMenuButton(defaultCategoryButton)
    }
    
    // MARK: - Load User Data & Prefrences
    private func loadUserData() {
        guard let authUser = Auth.auth().currentUser else {
            userNameLabel.text = "User Name"
            userEmailLabel.text = "No Email"
            currentUserProfile = nil
            return
        }
        
        userNameLabel.text = authUser.displayName ?? "User Name"
        userEmailLabel.text = authUser.email ?? "No Email"
        loadCachedProfileImage(for: authUser.uid)
        
        DataManager.shared.fetchUserProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    let repairedProfile = self?.profileWithAuthFallbacks(profile, authUser: authUser) ?? profile
                    self?.currentUserProfile = repairedProfile
                    self?.applyProfile(repairedProfile)
                    self?.loadSharedSettingsFromFirestore(email: authUser.email)
                    self?.saveMissingProfileFieldsIfNeeded(originalProfile: profile, repairedProfile: repairedProfile)
                    if let profileImageBase64 = repairedProfile.profileImageBase64,
                       let image = self?.image(fromBase64: profileImageBase64) {
                        self?.cacheProfileImageBase64(profileImageBase64, for: repairedProfile.uid)
                        self?.setProfileImage(image)
                    } else {
                        self?.loadCachedProfileImage(for: repairedProfile.uid)
                    }
                case .failure:
                    self?.currentUserProfile = nil
                    self?.loadCachedProfileImage(for: authUser.uid)
                    self?.loadSharedSettingsFromFirestore(email: authUser.email)
                }
            }
        }
    }
    
    private func loadSavedSettings(){
        // Dark Mode
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        darkModeSwitch?.isOn = isDarkMode
        applyDarkMode(isDarkMode)
        
        // Currency & category
        if let currency = UserDefaults.standard.string(forKey: "appCurrency"){
            currencyButton?.setTitle(currency, for: .normal)
            FormControlStyler.styleMenuButton(currencyButton, title: currency)
        }
        if let category = UserDefaults.standard.string(forKey: "defaultCategory"){
            defaultCategoryButton?.setTitle(category, for: .normal)
            FormControlStyler.styleMenuButton(defaultCategoryButton, title: category)
        }
        
        // Reminders
        let isReminderOn = UserDefaults.standard.bool(forKey: "dailyReminders")
        dailyRemindersSwitch?.isOn = isReminderOn
        reminderDatePicker?.isEnabled = isReminderOn
        
        if let savedReminderDate = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            reminderDatePicker?.date = savedReminderDate
        }
    }
    
    // MARK: - Table View Layout
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 104
        case 1:
            return 188
        case 2:
            return 206
        case 3:
            return 76
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        FormControlStyler.applyCellStyle(to: cell)
        if isProfileIndexPath(indexPath) {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
    }
    // MARK: - Actions
    
    @IBAction func darkModeToggled(_ sender: UISwitch) {
        AppearanceManager.applyDarkMode(sender.isOn)
        saveSharedSettings(["isDarkMode": sender.isOn])
    }
    
    @IBAction func dailyRemindersToggled(_ sender: UISwitch) {
        reminderDatePicker?.isEnabled = sender.isOn
        UserDefaults.standard.set(sender.isOn, forKey: "dailyReminders")
        saveSharedSettings(["dailyReminders": sender.isOn])
        
        if sender.isOn {
            requestNotificationPermission()
        }else{
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyExpenseReminder"])
        }
    }
    
    @IBAction func reminderTimeChanged(_ sender: UIDatePicker) {
        UserDefaults.standard.set(sender.date, forKey: "reminderTime")
        let components = Calendar.current.dateComponents([.hour, .minute], from: sender.date)
        saveSharedSettings([
            "reminderHour": components.hour ?? 9,
            "reminderMinute": components.minute ?? 0
        ])
        
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
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        present(alert, animated: true)
    }
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Log Out" , message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive){ [weak self] _ in
            do {
                SharedSettingsStore.stopListening()
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                try Auth.auth().signOut()
                self?.redirectToLogin()
            } catch {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func profileImageTapped() {
        showProfileImageOptions()
    }
    
    // MARK: - Table View Delegate
        // Allows tapping non-button cells directly if needed
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            if isProfileIndexPath(indexPath) {
                showAccountDetails()
            }
        }

        private func isProfileIndexPath(_ indexPath: IndexPath) -> Bool {
            indexPath.section == 0 && indexPath.row == 0
        }

        // MARK: - Helper Methods

        private func showAccountDetails() {
            guard Auth.auth().currentUser != nil else {
                showAlert(title: "Not Signed In", message: "Please log in to view your account details.")
                return
            }
            
            DataManager.shared.fetchUserProfile { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let profile) = result,
                       let authUser = Auth.auth().currentUser {
                        let repairedProfile = self?.profileWithAuthFallbacks(profile, authUser: authUser) ?? profile
                        self?.currentUserProfile = repairedProfile
                        self?.applyProfile(repairedProfile)
                        self?.saveMissingProfileFieldsIfNeeded(originalProfile: profile, repairedProfile: repairedProfile)
                    }
                    self?.presentAccountDetailsAlert()
                }
            }
        }
        
        private func presentAccountDetailsAlert() {
            guard let authUser = Auth.auth().currentUser else {
                showAlert(title: "Not Signed In", message: "Please log in to view your account details.")
                return
            }
            
            let profile = currentUserProfile
            let visibleName = usableVisibleName()
            let username = nonEmpty(profile?.username) ?? nonEmpty(authUser.displayName) ?? visibleName ?? usernameFromEmail(authUser.email) ?? ""
            let displayNameForSplit = nonEmpty(authUser.displayName) ?? visibleName ?? username
            let nameParts = splitDisplayName(displayNameForSplit)
            let firstName = nonEmpty(profile?.firstName) ?? nameParts.firstName ?? username
            let lastName = nonEmpty(profile?.lastName) ?? nameParts.lastName ?? ""
            let email = authUser.email ?? nonEmpty(profile?.email) ?? nonEmpty(userEmailLabel.text) ?? "No Email"
            let message = "Username: \(username)\nFirst Name: \(firstName)\nLast Name: \(lastName)\nEmail: \(email)"
            
            let alert = UIAlertController(title: "Account Details", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Change Profile Photo", style: .default) { [weak self] _ in
                self?.showProfileImageOptions()
            })
            alert.addAction(UIAlertAction(title: "Change Password", style: .default) { [weak self] _ in
                self?.showChangePasswordAlert()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
        
        private func applyProfile(_ profile: User) {
            if !profile.fullName.isEmpty {
                userNameLabel.text = profile.fullName
            } else if !profile.username.isEmpty {
                userNameLabel.text = profile.username
            } else {
                userNameLabel.text = Auth.auth().currentUser?.displayName ?? "User Name"
            }
            
            userEmailLabel.text = profile.email.isEmpty ? Auth.auth().currentUser?.email ?? "No Email" : profile.email
        }
        
        private func profileWithAuthFallbacks(_ profile: User, authUser: FirebaseAuth.User) -> User {
            let visibleName = usableVisibleName()
            let username = nonEmpty(profile.username) ?? nonEmpty(authUser.displayName) ?? visibleName ?? usernameFromEmail(authUser.email) ?? ""
            let displayNameForSplit = nonEmpty(authUser.displayName) ?? visibleName ?? username
            let nameParts = splitDisplayName(displayNameForSplit)
            return User(
                uid: profile.uid,
                email: nonEmpty(profile.email) ?? authUser.email ?? "",
                username: username,
                firstName: nonEmpty(profile.firstName) ?? nameParts.firstName ?? username,
                lastName: nonEmpty(profile.lastName) ?? nameParts.lastName ?? "",
                profileImageBase64: profile.profileImageBase64,
                preferredCurrency: profile.preferredCurrency
            )
        }
        
        private func saveMissingProfileFieldsIfNeeded(originalProfile: User, repairedProfile: User) {
            var updates: [String: Any] = [:]
            if originalProfile.email.isEmpty, !repairedProfile.email.isEmpty {
                updates["email"] = repairedProfile.email
            }
            if originalProfile.username.isEmpty, !repairedProfile.username.isEmpty {
                updates["username"] = repairedProfile.username
            }
            if originalProfile.firstName.isEmpty, !repairedProfile.firstName.isEmpty {
                updates["firstName"] = repairedProfile.firstName
            }
            if originalProfile.lastName.isEmpty, !repairedProfile.lastName.isEmpty {
                updates["lastName"] = repairedProfile.lastName
            }
            guard !updates.isEmpty else { return }
            
            Firestore.firestore().collection("users").document(repairedProfile.uid).setData(updates, merge: true)
        }
        
        private func splitDisplayName(_ displayName: String?) -> (firstName: String?, lastName: String?) {
            let parts = (displayName ?? "")
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            guard !parts.isEmpty else { return (nil, nil) }
            
            let firstName = parts.first
            let lastName = parts.dropFirst().isEmpty ? nil : parts.dropFirst().joined(separator: " ")
            return (firstName, lastName)
        }
        
        private func nonEmpty(_ value: String?) -> String? {
            guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
                return nil
            }
            return trimmedValue
        }
        
        private func usernameFromEmail(_ email: String?) -> String? {
            guard let email = nonEmpty(email), let username = email.components(separatedBy: "@").first else {
                return nil
            }
            return nonEmpty(username)
        }
        
        private func usableVisibleName() -> String? {
            guard let visibleName = nonEmpty(userNameLabel.text) else { return nil }
            let placeholderNames = ["User Name", "Username", "No Name", "Not set", "Not listed"]
            return placeholderNames.contains(visibleName) ? nil : visibleName
        }
        
        private func showProfileImageOptions() {
            let alert = UIAlertController(title: "Profile Photo", message: nil, preferredStyle: .actionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                    self?.presentImagePicker(sourceType: .camera)
                })
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                alert.addAction(UIAlertAction(title: "Choose From Gallery", style: .default) { [weak self] _ in
                    self?.presentImagePicker(sourceType: .photoLibrary)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.sourceView = profileImageView
            alert.popoverPresentationController?.sourceRect = profileImageView.bounds
            present(alert, animated: true)
        }
        
        private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            picker.dismiss(animated: true) { [weak self] in
                guard let selectedImage = selectedImage else { return }
                self?.saveProfileImage(selectedImage)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        private func saveProfileImage(_ image: UIImage) {
            guard let uid = Auth.auth().currentUser?.uid,
                  let resizedImage = resizedProfileImage(from: image),
                  let imageData = resizedImage.jpegData(compressionQuality: 0.65) else {
                showAlert(title: "Image Error", message: "Unable to save this profile image.")
                return
            }
            
            setProfileImage(resizedImage)
            let imageBase64 = imageData.base64EncodedString()
            cacheProfileImageBase64(imageBase64, for: uid)
            if let profile = currentUserProfile {
                currentUserProfile = User(
                    uid: profile.uid,
                    email: profile.email,
                    username: profile.username,
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    profileImageBase64: imageBase64,
                    preferredCurrency: profile.preferredCurrency
                )
            }
            
            saveSharedProfileValues(["profileImageBase64": imageBase64], uid: uid, email: Auth.auth().currentUser?.email) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Image Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        private func saveSharedSettings(_ values: [String: Any]) {
            guard let authUser = Auth.auth().currentUser else { return }
            saveSharedProfileValues(values, uid: authUser.uid, email: authUser.email) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Settings Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        private func saveSharedProfileValues(
            _ values: [String: Any],
            uid: String,
            email: String?,
            completion: @escaping (Error?) -> Void
        ) {
            let db = Firestore.firestore()
            let usersCollection = db.collection("users")
            var syncedValues = values
            let updatedAt = Timestamp(date: Date())
            syncedValues["settingsUpdatedAt"] = updatedAt
            if values["profileImageBase64"] != nil {
                syncedValues["profileImageUpdatedAt"] = updatedAt
            }
            if let email = nonEmpty(email) {
                syncedValues["email"] = email
            }
            
            let initialSaveGroup = DispatchGroup()
            var firstError: Error?
            
            initialSaveGroup.enter()
            usersCollection.document(uid).setData(syncedValues, merge: true) { error in
                if firstError == nil {
                    firstError = error
                }
                initialSaveGroup.leave()
            }
            
            if let email = nonEmpty(email) {
                initialSaveGroup.enter()
                accountSettingsDocument(for: email).setData(syncedValues, merge: true) { error in
                    if firstError == nil {
                        firstError = error
                    }
                    initialSaveGroup.leave()
                }
            }
            
            initialSaveGroup.notify(queue: .main) {
                if let firstError = firstError {
                    completion(firstError)
                    return
                }
                
                guard let email = self.nonEmpty(email) else {
                    completion(nil)
                    return
                }
                
                self.profileDocumentIDsMatchingEmail(email, currentUID: uid) { documentIDs in
                    let group = DispatchGroup()
                    var firstError: Error?
                    
                    documentIDs.forEach { documentID in
                        group.enter()
                        usersCollection.document(documentID).setData(syncedValues, merge: true) { error in
                            if firstError == nil {
                                firstError = error
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        completion(firstError)
                    }
                }
            }
        }
        
        private func loadSharedSettingsFromFirestore(email: String?) {
            guard let uid = Auth.auth().currentUser?.uid,
                  let email = nonEmpty(email) else { return }
            
            listenToAccountSettingsDocument(email: email)
            
            profileDocumentIDsMatchingEmail(email, currentUID: uid) { [weak self] documentIDs in
                self?.fetchProfileDocumentData(documentIDs: documentIDs) { documents in
                    guard let settings = documents.max(by: {
                        self?.settingsSortValue($0) ?? 0 < self?.settingsSortValue($1) ?? 0
                    }) else { return }
                    
                    DispatchQueue.main.async {
                        self?.applySharedSettings(settings)
                    }
                }
            }
        }
        
        private func accountSettingsDocument(for email: String) -> DocumentReference {
            Firestore.firestore()
                .collection("accountSettings")
                .document(accountSettingsDocumentID(for: email))
        }
        
        private func listenToAccountSettingsDocument(email: String) {
            sharedSettingsListener?.remove()
            sharedSettingsListener = accountSettingsDocument(for: email)
                .addSnapshotListener { [weak self] snapshot, _ in
                    guard let data = snapshot?.data() else { return }
                    DispatchQueue.main.async {
                        self?.applySharedSettings(data)
                    }
                }
        }
        
        private func fetchProfileDocumentData(
            documentIDs: Set<String>,
            completion: @escaping ([[String: Any]]) -> Void
        ) {
            let usersCollection = Firestore.firestore().collection("users")
            let group = DispatchGroup()
            let syncQueue = DispatchQueue(label: "profile-settings-documents")
            var documents: [[String: Any]] = []
            
            documentIDs.forEach { documentID in
                group.enter()
                usersCollection.document(documentID).getDocument { snapshot, _ in
                    if let data = snapshot?.data() {
                        syncQueue.sync {
                            documents.append(data)
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(documents)
            }
        }
        
        private func settingsScore(_ data: [String: Any]) -> Int {
            var score = 0
            if nonEmpty(data["preferredCurrency"] as? String) != nil || nonEmpty(data["currency"] as? String) != nil {
                score += 1
            }
            if nonEmpty(data["defaultCategory"] as? String) != nil {
                score += 1
            }
            if data["isDarkMode"] as? Bool != nil {
                score += 1
            }
            if data["dailyReminders"] as? Bool != nil {
                score += 1
            }
            if data["reminderHour"] as? Int != nil || data["reminderMinute"] as? Int != nil {
                score += 1
            }
            if nonEmpty(data["profileImageBase64"] as? String) != nil {
                score += 1
            }
            return score
        }
        
        private func settingsSortValue(_ data: [String: Any]) -> Double {
            if let updatedAt = data["settingsUpdatedAt"] as? Timestamp {
                return updatedAt.dateValue().timeIntervalSince1970
            }
            if let updatedAt = data["settingsUpdatedAt"] as? Date {
                return updatedAt.timeIntervalSince1970
            }
            if let updatedAt = data["settingsUpdatedAt"] as? TimeInterval {
                return updatedAt
            }
            return Double(settingsScore(data))
        }
        
        private func applySharedSettings(_ data: [String: Any]) {
            if let profileImageBase64 = nonEmpty(data["profileImageBase64"] as? String),
               let image = image(fromBase64: profileImageBase64) {
                setProfileImage(image)
                if let uid = Auth.auth().currentUser?.uid {
                    cacheProfileImageBase64(profileImageBase64, for: uid)
                }
            }
            
            if let currency = nonEmpty(data["preferredCurrency"] as? String) ?? nonEmpty(data["currency"] as? String) {
                currencyButton?.setTitle(currency, for: .normal)
                FormControlStyler.styleMenuButton(currencyButton, title: currency)
                UserDefaults.standard.set(currency, forKey: "appCurrency")
            }
            
            if let category = nonEmpty(data["defaultCategory"] as? String) {
                defaultCategoryButton?.setTitle(category, for: .normal)
                FormControlStyler.styleMenuButton(defaultCategoryButton, title: category)
                UserDefaults.standard.set(category, forKey: "defaultCategory")
            }
            
            if let isDarkMode = data["isDarkMode"] as? Bool {
                darkModeSwitch?.isOn = isDarkMode
                AppearanceManager.applyDarkMode(isDarkMode)
            }
            
            if let dailyReminders = data["dailyReminders"] as? Bool {
                dailyRemindersSwitch?.isOn = dailyReminders
                reminderDatePicker?.isEnabled = dailyReminders
                UserDefaults.standard.set(dailyReminders, forKey: "dailyReminders")
            }
            
            if let reminderDate = reminderDate(from: data) {
                reminderDatePicker?.date = reminderDate
                UserDefaults.standard.set(reminderDate, forKey: "reminderTime")
                if dailyRemindersSwitch.isOn {
                    scheduleDailyNotification(at: reminderDate)
                }
            }
        }
        
        private func reminderDate(from data: [String: Any]) -> Date? {
            guard let hour = data["reminderHour"] as? Int,
                  let minute = data["reminderMinute"] as? Int else { return nil }
            return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
        }
        
        private func applyDarkMode(_ isDarkMode: Bool) {
            AppearanceManager.applyDarkMode(isDarkMode)
        }
        
        private func profileDocumentIDsMatchingEmail(
            _ email: String,
            currentUID: String,
            completion: @escaping (Set<String>) -> Void
        ) {
            let db = Firestore.firestore()
            let usersCollection = db.collection("users")
            let emailValues = Array(Set([email, email.lowercased()]))
            let emailFields = ["email", "userEmail", "Email"]
            let group = DispatchGroup()
            let syncQueue = DispatchQueue(label: "profile-photo-document-ids")
            var documentIDs = Set([currentUID])
            
            func addMatchingDocuments(from snapshot: QuerySnapshot?) {
                snapshot?.documents.forEach { document in
                    guard self.documentEmailMatches(document.data(), email: email) else { return }
                    _ = syncQueue.sync {
                        documentIDs.insert(document.documentID)
                    }
                }
            }
            
            emailFields.forEach { field in
                emailValues.forEach { emailValue in
                    group.enter()
                    usersCollection.whereField(field, isEqualTo: emailValue).getDocuments { snapshot, _ in
                        addMatchingDocuments(from: snapshot)
                        group.leave()
                    }
                }
            }
            
            group.enter()
            usersCollection.limit(to: 100).getDocuments { snapshot, _ in
                addMatchingDocuments(from: snapshot)
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(documentIDs)
            }
        }
        
        private func documentEmailMatches(_ data: [String: Any], email: String) -> Bool {
            let normalizedEmail = email.lowercased()
            let emailKeys = ["email", "userEmail", "Email"]
            return emailKeys.contains { key in
                guard let value = data[key] as? String else { return false }
                return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedEmail
            }
        }
        
        private func accountSettingsDocumentID(for email: String) -> String {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let data = Data(normalizedEmail.utf8)
            return data.base64EncodedString()
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "=", with: "")
        }
        
        private func resizedProfileImage(from image: UIImage) -> UIImage? {
            let targetSize = CGSize(width: 240, height: 240)
            guard image.size.width > 0, image.size.height > 0 else { return nil }
            
            let scale = max(targetSize.width / image.size.width, targetSize.height / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let drawRect = CGRect(
                x: (targetSize.width - scaledSize.width) / 2,
                y: (targetSize.height - scaledSize.height) / 2,
                width: scaledSize.width,
                height: scaledSize.height
            )
            
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                image.draw(in: drawRect)
            }
        }
        
        private func setProfileImage(_ image: UIImage) {
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.image = image
        }
        
        private func setDefaultProfileImage() {
            profileImageView.contentMode = .scaleAspectFit
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        
        private func cacheProfileImageBase64(_ value: String, for uid: String) {
            UserDefaults.standard.set(value, forKey: profileImageCacheKey(for: uid))
        }
        
        private func loadCachedProfileImage(for uid: String) {
            guard let cachedImageBase64 = UserDefaults.standard.string(forKey: profileImageCacheKey(for: uid)),
                  let image = image(fromBase64: cachedImageBase64) else {
                setDefaultProfileImage()
                return
            }
            
            setProfileImage(image)
        }
        
        private func profileImageCacheKey(for uid: String) -> String {
            return "profileImageBase64_\(uid)"
        }
        
        private func image(fromBase64 value: String) -> UIImage? {
            guard let data = Data(base64Encoded: value) else { return nil }
            return UIImage(data: data)
        }
        
        private func showChangePasswordAlert() {
            let alert = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Old password"
                textField.isSecureTextEntry = true
            }
            alert.addTextField { textField in
                textField.placeholder = "New password"
                textField.isSecureTextEntry = true
            }
            alert.addTextField { textField in
                textField.placeholder = "Confirm new password"
                textField.isSecureTextEntry = true
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Update", style: .default) { [weak self, weak alert] _ in
                guard let textFields = alert?.textFields,
                      textFields.count == 3 else { return }
                
                let oldPassword = textFields[0].text ?? ""
                let newPassword = textFields[1].text ?? ""
                let confirmPassword = textFields[2].text ?? ""
                self?.changePassword(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword)
            })
            present(alert, animated: true)
        }
        
        private func changePassword(oldPassword: String, newPassword: String, confirmPassword: String) {
            guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
                showAlert(title: "Missing Information", message: "Please fill in all password fields.")
                return
            }
            
            guard newPassword == confirmPassword else {
                showAlert(title: "Passwords do not match", message: "Please confirm the new password again.")
                return
            }
            
            guard newPassword.count >= 6 else {
                showAlert(title: "Weak Password", message: "The new password must be at least 6 characters.")
                return
            }
            
            guard let authUser = Auth.auth().currentUser,
                  let email = authUser.email else {
                showAlert(title: "Not Signed In", message: "Please log in again before changing your password.")
                return
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
            authUser.reauthenticate(with: credential) { [weak self] _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Password Update Failed", message: error.localizedDescription)
                    }
                    return
                }
                
                authUser.updatePassword(to: newPassword) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(title: "Password Update Failed", message: error.localizedDescription)
                        } else {
                            self?.showAlert(title: "Password Updated", message: "Your password has been changed.")
                        }
                    }
                }
            }
        }

        private func performDataDeletion() {
            guard let expensesCollection = ExpenseStore.currentExpensesCollection else { return }
            
            expensesCollection.getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let group = DispatchGroup()
                
                for doc in documents {
                    group.enter()
                    ExpenseStore.deleteExpenseEverywhere(id: doc.documentID) { _ in
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self?.showAlert(title: "Success", message: "All expense data has been cleared.")
                }
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
                    AppearanceManager.applyLightMode()
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
