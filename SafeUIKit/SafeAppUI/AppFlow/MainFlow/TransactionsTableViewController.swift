//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import BlockiesSwift

public class TransactionsTableViewController: UITableViewController {

    private var groups = [TransactionGroup]()

    public static func create() -> TransactionsTableViewController {
        return StoryboardScene.Main.transactionsTableViewController.instantiate()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "TransactionsGroupHeaderView",
                                 bundle: Bundle(for: TransactionsGroupHeaderView.self)),
                           forHeaderFooterViewReuseIdentifier: "TransactionsGroupHeaderView")
        groups = generateTransactions()
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].transactions.count
    }

    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TransactionsGroupHeaderView")
            as! TransactionsGroupHeaderView
        view.configure(group: groups[section])
        return view
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell",
                                                 for: indexPath) as! TransactionTableViewCell
        cell.configure(transaction: groups[indexPath.section].transactions[indexPath.row])
        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func generateTransactions() -> [TransactionGroup] {
        let pending = TransactionGroup(name: "PENDING", transactions: [
            TransactionOverview(transactionDescription: "Johny Cash",
                                formattedDate: "1 secs ago",
                                status: .success,
                                tokenAmount: "-2.42453 ETH",
                                fiatAmount: "$1,429.42",
                                type: .outgoing,
                                actionDescription: nil,
                                icon: iconImage(seed: "Johny Cash")),
            TransactionOverview(transactionDescription: "Martin Winklervos",
                                formattedDate: "6 mins ago",
                                status: .success,
                                tokenAmount: "-1.10000 ETH",
                                fiatAmount: "$643.42",
                                type: .outgoing,
                                actionDescription: nil,
                                icon: iconImage(seed: "Martin Winklervos"))])
        let today = TransactionGroup(name: "TODAY", transactions: [
            TransactionOverview(transactionDescription: "Martin Winklervos (failed)",
                                formattedDate: "15 mins ago",
                                status: .failed,
                                tokenAmount: "-1.10000 ETH",
                                fiatAmount: "$643.42",
                                type: .outgoing,
                                actionDescription: nil,
                                icon: UIImage()),
            TransactionOverview(transactionDescription: "0x828b8fb3fcbf2d7d73d69ea78efc5d5d8e136b48",
                                formattedDate: "2hrs 2 mins ago",
                                status: .success,
                                tokenAmount: "+23.14454 ETH",
                                fiatAmount: "$5,913.12",
                                type: .incoming,
                                actionDescription: nil,
                                icon: iconImage(seed: "Martin Winklervos"))])
        let yesterday = TransactionGroup(name: "YESTERDAY", transactions: [
            TransactionOverview(transactionDescription: "0x0be5bb0e39b38970b2d7c40ff0b2e1f0521dd8da",
                                formattedDate: "1 day 2hrs ago",
                                status: .success,
                                tokenAmount: "+9.11300 ETH",
                                fiatAmount: "$11,492.04",
                                type: .incoming,
                                actionDescription: nil,
                                icon: iconImage(seed: "0x0be5bb0e39b38970b2d7c40ff0b2e1f0521dd8da")),
            TransactionOverview(transactionDescription: "Changed device",
                                formattedDate: "1 day 9hrs ago",
                                status: .success,
                                tokenAmount: nil,
                                fiatAmount: nil,
                                type: .settings,
                                actionDescription: "SETTINGS\nCHANGE",
                                icon: Asset.TransactionOverviewIcons.settingTransaction.image)])
        return [pending, today, yesterday]
    }

    private func iconImage(seed: String) -> UIImage {
        let blockies = Blockies(seed: seed,
                                size: 8,
                                scale: 5)
        return blockies.createImage(customScale: 3)!
    }

}

struct TransactionGroup {
    var name: String
    var transactions: [TransactionOverview]
}

struct TransactionOverview {

    var transactionDescription: String
    var formattedDate: String
    var status: TransactionStatus
    var tokenAmount: String?
    var fiatAmount: String?
    var type: TransactionType
    var actionDescription: String?
    var icon: UIImage

}

enum TransactionType {
    case incoming
    case outgoing
    case settings
}

enum TransactionStatus {
    case pending
    case success
    case failed
}
