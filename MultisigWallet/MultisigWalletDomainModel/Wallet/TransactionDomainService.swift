//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class TransactionDomainService {

    public init() {}

    public func removeDraftTransaction(_ id: TransactionID) {
        let repository = DomainRegistry.transactionRepository
        if let transaction = repository.find(id: id), transaction.status == .draft {
            repository.remove(transaction)
        }
    }

    public func newDraftTransaction() -> TransactionID {
        return newDraftTransaction(in: DomainRegistry.walletRepository.selectedWallet()!)
    }

    public func newDraftTransaction(in wallet: Wallet) -> TransactionID {
        let repository = DomainRegistry.transactionRepository
        let transaction = Transaction(id: repository.nextID(),
                                      type: .transfer,
                                      walletID: wallet.id,
                                      accountID: AccountID(tokenID: Token.Ether.id, walletID: wallet.id))
        transaction.change(sender: wallet.address!)
        repository.save(transaction)
        return transaction.id
    }

    public func allTransactions() -> [Transaction] {
        let all = DomainRegistry.transactionRepository.all()
        return all
            .filter { tx in
                tx.status != .draft &&
                tx.status != .signing &&
                tx.status != .discarded &&
                tx.status != .rejected
            }
            .sorted { lhs, rhs in
                var lDates = lhs.allEventDates.makeIterator()
                var rDates = rhs.allEventDates.makeIterator()
                while true {
                    switch (lDates.next(), rDates.next()) {
                    case (.none, .some):
                        return true
                    case (.some, .none):
                        return false
                    case let (.some(left), .some(right)) where left == right:
                        continue
                    case let (.some(left), .some(right)):
                        return left > right
                    case (.none, .none):
                        if lhs.status == rhs.status {
                            return lhs.id.id < rhs.id.id
                        } else {
                            return lhs.status.rawValue < rhs.status.rawValue
                        }
                    }
                }
        }
    }

    /// Groups transactions by day, in reverse chronologic order, with pending transaction as 1st group.
    public func grouppedTransactions() -> [TransactionGroup] {
        var pendingGroup = TransactionGroup(type: .pending, date: nil, transactions: [])
        var todayGroup = TransactionGroup(type: .processed, date: Date().dateForGrouping, transactions: [])
        var pastGroup = TransactionGroup(type: .processed, date: Date.distantPast.dateForGrouping, transactions: [])
        for tx in allTransactions() {
            if tx.status == .pending {
                pendingGroup.transactions.append(tx)
                continue
            }
            precondition(tx.allEventDates.first != nil, "Transaction must be timestamped: \(tx)")
            let txDate = tx.allEventDates.first!.dateForGrouping
            if txDate.isToday || txDate.isInTheFuture {
                todayGroup.transactions.append(tx)
            } else {
                pastGroup.transactions.append(tx)
            }
        }
        return ([pendingGroup, todayGroup, pastGroup]).filter { !$0.transactions.isEmpty }
    }

    public func updatePendingTransactions() throws {
        let transactions = DomainRegistry.transactionRepository.all().filter { $0.status == .pending }
        let nodeService = DomainRegistry.ethereumNodeService
        var hasUpdates = false
        for tx in transactions {
            assert(tx.transactionHash != nil, "Transaction must have a blockchain hash: \(tx)")
            let receipt = try nodeService.eth_getTransactionReceipt(transaction: tx.transactionHash!)
            if let receipt = receipt {
                let block = try nodeService.eth_getBlockByHash(hash: receipt.blockHash)
                assert(block != nil, "Transaction receipt must have a block: \(receipt)")
                if receipt.status == .success {
                    tx.succeed()
                } else {
                    tx.fail()
                }
                timestamp(transaction: tx, from: block!)
                hasUpdates = true
            }
        }
        if hasUpdates {
            DomainRegistry.eventPublisher.publish(TransactionStatusUpdated())
        }
    }

    public func updateTimestampsOfProcessedTransactions() throws {
        let transactions = DomainRegistry.transactionRepository.all()
            .filter { $0.status == .success || $0.status == .failed }
        let nodeService = DomainRegistry.ethereumNodeService
        for tx in transactions {
            assert(tx.transactionHash != nil, "Transaction hash is missing: \(tx)")

            let receipt = try nodeService.eth_getTransactionReceipt(transaction: tx.transactionHash!)
            assert(receipt != nil, "Transaction must have a receipt: \(tx)")

            let block = try nodeService.eth_getBlockByHash(hash: receipt!.blockHash)
            assert(block != nil, "Receipt must have block: \(receipt!)")

            timestamp(transaction: tx, from: block!)
        }
        if !transactions.isEmpty {
            DomainRegistry.eventPublisher.publish(TransactionStatusUpdated())
        }
    }

    private func timestamp(transaction: Transaction, from block: EthBlock) {
        transaction.timestampProcessed(at: block.timestamp).timestampUpdated(at: Date())
        DomainRegistry.transactionRepository.save(transaction)
    }

}

public class TransactionStatusUpdated: DomainEvent {}

fileprivate extension Transaction {

    var allEventDates: [Date] {
        return [processedDate, submittedDate, rejectedDate, updatedDate, createdDate].compactMap { $0 }
    }

}

public extension Date {

    var dateForGrouping: Date {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.date(from: calendar.dateComponents([.era, .year, .month, .day], from: self))!
    }

}

fileprivate extension Date {

    var isToday: Bool {
        return Calendar.autoupdatingCurrent.isDateInToday(self)
    }

    var isInTheFuture: Bool {
        return self > Date()
    }

}
