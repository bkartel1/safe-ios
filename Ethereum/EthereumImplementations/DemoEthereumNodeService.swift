//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import EthereumDomainModel
import CommonTestSupport

public class DemoEthereumNodeService: EthereumNodeDomainService {

    public init() {}

    private var balanceUpdateCounter = 0

    public func eth_getBalance(account: Address) throws -> Ether {
        delay(2)
        if account.value == "0x57b2573E5FA7c7C9B5Fa82F3F03A75F53A0efdF5" {
            let balance = Ether(amount: min(balanceUpdateCounter * 100, 100))
            balanceUpdateCounter += 1
            return balance
        } else {
            return Ether.zero
        }
    }

    private var receiptUpdateCounter = 0

    public func eth_getTransactionReceipt(transaction: TransactionHash) throws -> TransactionReceipt? {
        delay(2)
        if receiptUpdateCounter == 3 {
            return TransactionReceipt(hash: transaction, status: .success)
        } else {
            receiptUpdateCounter += 1
            return nil
        }
    }

}