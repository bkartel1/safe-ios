//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletImplementations
import MultisigWalletDomainModel
import CommonTestSupport

class SynchronisationServiceTests: XCTestCase {

    var syncService: SynchronisationService!
    let tokenListService = MockTokenListService()
    let accountService = MockAccountUpdateService()
    let tokenListItemRepository = InMemoryTokenListItemRepository()
    let portfolioRepository = InMemorySinglePortfolioRepository()
    let walletRepository = InMemoryWalletRepository()
    let publisher = MockEventPublisher()
    let retryInterval: TimeInterval = 0.5

    override func setUp() {
        super.setUp()
        DomainRegistry.put(service: tokenListService, for: TokenListDomainService.self)
        DomainRegistry.put(service: tokenListItemRepository, for: TokenListItemRepository.self)
        DomainRegistry.put(service: portfolioRepository, for: SinglePortfolioRepository.self)
        DomainRegistry.put(service: walletRepository, for: WalletRepository.self)
        DomainRegistry.put(service: publisher, for: EventPublisher.self)
        syncService = SynchronisationService(retryInterval: retryInterval, accountService: accountService)
    }

    func test_whenSync_thenCallsTokenListService() {
        startSync()
        delay(retryInterval)
        assertTokenListSyncSuccess()
    }

    func test_whenFailsToGetTokensList_thenRetries() {
        tokenListService.shouldThrow = true
        startSync()
        delay(retryInterval)
        assertTokenListSyncInProgress()
        tokenListService.shouldThrow = false
        delay(retryInterval * 3)
        assertTokenListSyncSuccess()
    }

    func test_whenSync_thenCallsAccountUpdateDomainService() {
        startSync()
        delay(retryInterval * 2)
    }

}

private extension SynchronisationServiceTests {

    func startSync() {
        publisher.expectToPublish(TokenListMerged.self)
        XCTAssertFalse(tokenListService.didReturnItems)
        DispatchQueue.global().async {
            self.syncService.sync()
        }
    }

    private func assertTokenListSyncSuccess() {
        XCTAssertTrue(tokenListService.didReturnItems)
        XCTAssertTrue(publisher.verify())
    }

    private func assertTokenListSyncInProgress() {
        XCTAssertFalse(tokenListService.didReturnItems)
    }

    private func assertAccountSyncSuccess() {
        XCTAssertTrue(accountService.didUpdateBalances)
    }

}

fileprivate extension MockEventPublisher {

    func verify(_ line: UInt = #line) {
        XCTAssertTrue(publishedWhatWasExpected(), line: line)
    }

}
