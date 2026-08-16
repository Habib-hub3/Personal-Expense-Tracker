//
//  ExpensesTableViewController.swift
//  PersonalExpensesTracker
//
//  Created by Habib Alshoofa on 16/08/2026.
//

import UIKit

class ExpensesTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableLayout()
    }

    private func configureTableLayout() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.insetsContentViewsToSafeArea = true
        tableView.contentInsetAdjustmentBehavior = .automatic
    }
}
