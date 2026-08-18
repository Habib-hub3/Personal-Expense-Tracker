//
//  FormTextFieldStyler.swift
//  PersonalExpensesTracker
//

import UIKit

enum FormTextFieldStyler {
    static let fieldHeight: CGFloat = 44
    static let rowHeight: CGFloat = 64
    
    static func apply(to fields: [UITextField?]) {
        fields.compactMap { $0 }.forEach(apply(to:))
    }
    
    static func apply(to textField: UITextField) {
        textField.borderStyle = .none
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.tintColor = .systemBlue
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.clipsToBounds = true
        textField.autocorrectionType = .default
        textField.clearButtonMode = .whileEditing
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: fieldHeight))
        textField.leftView = padding
        textField.leftViewMode = .always
        
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        }
    }
    
    static func constrain(_ textField: UITextField, in contentView: UIView, horizontalPadding: CGFloat = 20) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            constraint.firstItem === textField || constraint.secondItem === textField
        })
        NSLayoutConstraint.deactivate(textField.constraints.filter { constraint in
            constraint.firstAttribute == .height || constraint.secondAttribute == .height
        })
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
    }
}
