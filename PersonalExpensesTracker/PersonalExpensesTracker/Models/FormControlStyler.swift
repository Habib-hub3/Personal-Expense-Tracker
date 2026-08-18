//
//  FormControlStyler.swift
//  PersonalExpensesTracker
//

import UIKit

@MainActor
enum FormControlStyler {
    static let controlHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 20
    static let maximumContentWidth: CGFloat = 680
    
    static func applyCellStyle(to cell: UITableViewCell) {
        cell.backgroundColor = .systemBackground
        cell.contentView.backgroundColor = .systemBackground
        cell.tintColor = .systemBlue
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .tertiarySystemFill
        cell.selectedBackgroundView = selectedBackgroundView
        
        styleLabels(in: cell.contentView)
    }
    
    static func styleMenuButton(_ button: UIButton?, title: String? = nil) {
        guard let button else { return }
        let buttonTitle = title ?? button.title(for: .normal) ?? button.configuration?.title ?? "Select"
        var configuration = UIButton.Configuration.filled()
        configuration.title = buttonTitle
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.baseBackgroundColor = .secondarySystemBackground
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        button.tintColor = .label
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
    }
    
    static func styleFilledButton(_ button: UIButton?, title: String? = nil, color: UIColor = .systemBlue) {
        guard let button else { return }
        var configuration = UIButton.Configuration.filled()
        configuration.title = title ?? button.title(for: .normal) ?? button.configuration?.title
        configuration.baseBackgroundColor = color
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
        button.tintColor = color
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
    }
    
    static func stylePlainButton(_ button: UIButton?, title: String? = nil) {
        guard let button else { return }
        var configuration = UIButton.Configuration.gray()
        configuration.title = title ?? button.title(for: .normal) ?? button.configuration?.title
        configuration.baseBackgroundColor = .secondarySystemBackground
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
        button.tintColor = .label
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
    }
    
    static func constrainButton(_ button: UIButton, in contentView: UIView, maximumWidth: CGFloat = 680) {
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            constraint.firstItem === button || constraint.secondItem === button
        })
        NSLayoutConstraint.deactivate(button.constraints.filter { constraint in
            constraint.firstAttribute == .height || constraint.secondAttribute == .height
        })
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: horizontalPadding),
            button.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -horizontalPadding),
            button.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth),
            button.heightAnchor.constraint(equalToConstant: controlHeight),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private static func styleLabels(in view: UIView) {
        view.subviews.forEach { subview in
            if let label = subview as? UILabel {
                label.textColor = label.textColor == .secondaryLabel || label.font.pointSize < 16 ? .secondaryLabel : .label
            }
            styleLabels(in: subview)
        }
    }
}
