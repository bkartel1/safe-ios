//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletImplementations
import MultisigWalletDomainModel
import Database

class DBAccountRepositoryIntegrationTests: XCTestCase {

    func test_all() throws {
        let db = SQLiteDatabase(name: String(reflecting: self),
                                fileManager: FileManager.default,
                                sqlite: CSQLite3(),
                                bundleId: String(reflecting: self))
        try? db.destroy()
        try db.create()
        defer {
            try? db.destroy()
        }

        let repo = DBAccountRepository(db: db)
        try repo.setUp()

        let walletID = try WalletID()
        let account = Account(id: AccountID(token: "ETH"),
                              walletID: walletID,
                              balance: 123,
                              minimumAmount: 12)
        try repo.save(account)
        let saved = try repo.find(id: account.id, walletID: walletID)
        XCTAssertEqual(saved, account)
        XCTAssertEqual(saved?.balance, account.balance)
        XCTAssertEqual(saved?.minimumTransactionAmount, account.minimumTransactionAmount)

        try repo.remove(account)
        XCTAssertNil(try repo.find(id: account.id, walletID: walletID))
    }

}