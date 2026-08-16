//
//  ExpensesFormTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit

class ExpensesFormTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableLayout()
    }

    private func configureTableLayout() {
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.sectionHeaderTopPadding = 12
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.insetsContentViewsToSafeArea = true
    }
}
