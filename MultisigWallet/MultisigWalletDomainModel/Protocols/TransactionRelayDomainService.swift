//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol TransactionRelayDomainService {

    func createSafeCreationTransaction(
        request: SafeCreationTransactionRequest) throws -> SafeCreationTransactionRequest.Response
    func startSafeCreation(address: Address) throws
    func safeCreationTransactionHash(address: Address) throws -> TransactionHash?
    func gasPrice() throws -> SafeGasPriceResponse
    func submitTransaction(request: SubmitTransactionRequest) throws -> SubmitTransactionRequest.Response
    func estimateTransaction(request: EstimateTransactionRequest) throws -> EstimateTransactionRequest.Response

}
