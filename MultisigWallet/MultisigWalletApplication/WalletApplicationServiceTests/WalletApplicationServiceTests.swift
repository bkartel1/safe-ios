//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletApplication
import MultisigWalletDomainModel
import Common

class WalletApplicationServiceTests: BaseWalletApplicationServiceTests {

    func test_whenDeployingWallet_thenResetsPublisherAndSubscribes() {
        let subscriber = MySubscriber()
        errorStream.expect_removeHandler(subscriber)
        eventRelay.expect_unsubscribe(subscriber)

        eventRelay.expect_subscribe(subscriber, for: DeploymentStarted.self)
        eventRelay.expect_subscribe(subscriber, for: StartedWaitingForFirstDeposit.self)
        eventRelay.expect_subscribe(subscriber, for: StartedWaitingForRemainingFeeAmount.self)
        eventRelay.expect_subscribe(subscriber, for: DeploymentFunded.self)
        eventRelay.expect_subscribe(subscriber, for: CreationStarted.self)
        eventRelay.expect_subscribe(subscriber, for: WalletTransactionHashIsKnown.self)
        eventRelay.expect_subscribe(subscriber, for: WalletCreated.self)
        eventRelay.expect_subscribe(subscriber, for: WalletCreationFailed.self)

        errorStream.expect_addHandler()
        deploymentService.expect_start()
        // swiftlint:disable:next trailing_closure
        service.deployWallet(subscriber: subscriber, onError: { _ in /* empty */ })
        XCTAssertTrue(deploymentService.verify())
        XCTAssertTrue(eventRelay.verify())
        XCTAssertTrue(errorStream.verify())
    }

    func test_whenWalletStateQueried_thenReturnsWalletState() {
        service.createNewDraftWallet()
        XCTAssertNotNil(service.walletState())
    }

    func test_whenCreatingNewDraft_thenCreatesPortfolio() throws {
        service.createNewDraftWallet()
        XCTAssertNotNil(portfolioRepository.portfolio())
    }

    func test_whenCreatingNewDraft_thenCreatesNewWallet() throws {
        givenDraftWallet()
        let wallet = selectedWallet
        XCTAssertTrue(wallet.state === wallet.newDraftState)
    }

    func test_whenAddingAccount_thenCanFindIt() throws {
        givenDraftWallet()
        let wallet = selectedWallet
        let ethAccountID = AccountID(tokenID: Token.Ether.id, walletID: wallet.id)
        let account = accountRepository.find(id: ethAccountID)
        XCTAssertNotNil(account)
        XCTAssertEqual(account?.id, ethAccountID)
        XCTAssertEqual(account?.balance, nil)
    }

    func test_whenAddingOwner_thenAddressCanBeFound() throws {
        givenDraftWallet()
        service.addOwner(address: Address.paperWalletAddress.value, type: .paperWallet)
        XCTAssertEqual(service.ownerAddress(of: .paperWallet), Address.paperWalletAddress.value)
    }

    func test_whenAddingAlreadyExistingTypeOfOwner_thenOldOwnerIsReplaced() throws {
        givenDraftWallet()
        service.addOwner(address: Address.extensionAddress.value, type: .browserExtension)
        service.addOwner(address: Address.extensionAddress.value, type: .browserExtension)
        XCTAssertEqual(service.ownerAddress(of: .browserExtension), Address.extensionAddress.value)
        service.addOwner(address: Address.testAccount1.value, type: .browserExtension)
        XCTAssertEqual(service.ownerAddress(of: .browserExtension), Address.testAccount1.value)
    }

    func test_whenWalletIsReady_thenHasReadyState() throws {
        createPortfolio()
        service.createNewDraftWallet()
        let wallet = walletRepository.selectedWallet()!
        wallet.state = wallet.readyToUseState
        walletRepository.save(wallet)
        XCTAssertTrue(service.hasReadyToUseWallet)
    }

    func test_whenAddressIsKnown_thenReturnsIt() throws {
        givenDraftWallet()
        let wallet = walletRepository.selectedWallet()!
        wallet.state = wallet.deployingState
        wallet.changeAddress(Address.safeAddress)
        walletRepository.save(wallet)
        XCTAssertEqual(service.selectedWalletAddress, Address.safeAddress.value)
    }

    func test_whenAccountMinimumAmountIsKnown_thenReturnsIt() throws {
        givenDraftWallet()
        let wallet = walletRepository.selectedWallet()!
        wallet.state = wallet.deployingState
        wallet.updateMinimumTransactionAmount(100)
        walletRepository.save(wallet)
        XCTAssertEqual(service.minimumDeploymentAmount, 100)
    }

    func test_whenFeePaymentTokenIsNil_thenReturnsEther() {
        givenDraftWallet()
        XCTAssertEqual(service.feePaymentTokenData.address, TokenData.Ether.address)
    }

    func test_whenFeePaymentTokenIsNotKnown_thenReturnsEther() {
        let item = createWalletWithFeeTokenItem(Token.gno, tokenItemStatus: .whitelisted)
        tokenItemsRepository.remove(item)
        let wallet = walletRepository.selectedWallet()!
        XCTAssertEqual(wallet.feePaymentTokenAddress, Token.gno.address)
        XCTAssertEqual(service.feePaymentTokenData.address, TokenData.Ether.address)
    }

    func test_whenFeePaymentTokenIsKnown_thenReturnsIt() {
        createWalletWithFeeTokenItem(Token.gno, tokenItemStatus: .whitelisted)
        service.changePaymentToken(TokenData(token: Token.gno, balance: nil))
        XCTAssertEqual(service.feePaymentTokenData, TokenData(token: Token.gno, balance: nil))
    }

    func test_whenChangingPaymentToken_thenItIsWhitelisted() {
        createWalletWithFeeTokenItem(Token.gno, tokenItemStatus: .regular)
        let gnoTokenData = TokenData(token: Token.gno, balance: nil)
        service.changePaymentToken(gnoTokenData)
        let whitelistedAddresses = service.visibleTokens(withEth: false).map { $0.address }
        XCTAssertTrue(whitelistedAddresses.contains(gnoTokenData.address))
    }

    func test_whenChangingPaymentTokenAsEther_thenItIsNotWhitelisted() {
        createWalletWithFeeTokenItem(Token.gno, tokenItemStatus: .regular)
        let ethTokenData = TokenData(token: Token.Ether, balance: nil)
        service.changePaymentToken(ethTokenData)
        let whitelistedAddresses = service.visibleTokens(withEth: false).map { $0.address }
        XCTAssertFalse(whitelistedAddresses.contains(ethTokenData.address))
    }

    @discardableResult
    private func createWalletWithFeeTokenItem(_ token: Token,
                                              tokenItemStatus: TokenListItem.TokenListItemStatus) -> TokenListItem {
        let item = TokenListItem(token: token, status: tokenItemStatus, canPayTransactionFee: true)
        tokenItemsRepository.save(item)
        givenDraftWallet()
        service.changePaymentToken(TokenData(token: token, balance: nil))
        return item
    }

}
