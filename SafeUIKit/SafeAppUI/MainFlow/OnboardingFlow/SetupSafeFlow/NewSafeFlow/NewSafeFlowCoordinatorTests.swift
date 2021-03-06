//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import CommonTestSupport
import Common
import MultisigWalletApplication

class NewSafeFlowCoordinatorTests: SafeTestCase {

    var newSafeFlowCoordinator: NewSafeFlowCoordinator!
    let nav = UINavigationController()
    var startVC: UIViewController!
    var pairVC: PairWithBrowserExtensionViewController?
    let address = "test_address"

    var topViewController: UIViewController? {
        return newSafeFlowCoordinator.navigationController.topViewController
    }

    override func setUp() {
        super.setUp()
        newSafeFlowCoordinator = NewSafeFlowCoordinator(rootViewController: UINavigationController())
        newSafeFlowCoordinator.setUp()
    }

    func test_startViewController_returnsSetupSafeStartVC() {
        assert(topViewController, is: GuidelinesViewController.self)
    }

    func test_didSelectBrowserExtensionSetup_showsController() {
        newSafeFlowCoordinator.didSelectBrowserExtensionSetup()
        delay()
        XCTAssertTrue(topViewController is PairWithBrowserExtensionViewController)
    }

    func test_pairWithBrowserExtensionCompletion_thenAddsBowserExtensionAndPopsToStartVC() {
        XCTAssertFalse(walletService.isOwnerExists(.browserExtension))
        pairWithBrowserExtension()
        XCTAssertTrue(walletService.isOwnerExists(.browserExtension))
        XCTAssertTrue(topViewController === startVC)
    }

    func test_whenWalletServiceThrowsDuringPairing_thenAlertIsHandled() {
        walletService.shouldThrow = true
        pairWithBrowserExtension()
        XCTAssertAlertShown(message: PairWithBrowserExtensionViewController.Strings.invalidCode)
        XCTAssertTrue(topViewController === pairVC)
    }

    func test_whenSelectedPaperWalletSetup_thenTransitionsToPaperWalletCoordinator() {
        let testFC = TestFlowCoordinator()
        testFC.enter(flow: PaperWalletFlowCoordinator())
        let expectedViewController = testFC.topViewController

        newSafeFlowCoordinator.didSelectPaperWalletSetup()

        let finalTransitionedViewController = newSafeFlowCoordinator.navigationController.topViewController
        XCTAssertTrue(type(of: finalTransitionedViewController) == type(of: expectedViewController))
    }

    func test_didSelectNext_presentsNextController() {
        newSafeFlowCoordinator.didSelectNext()
        delay()
        assert(topViewController, is: SafeCreationViewController.self)
    }

    func assert<T>(_ object: Any?, is aType: T.Type, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(object is T,
                      "Expected \(T.self) but got \(String(describing: type(of: object)))",
                      file: file,
                      line: line)
    }

    func test_paperWalletSetupCompletion_popsToStartVC() {
        let startVC = topViewController
        newSafeFlowCoordinator.didSelectPaperWalletSetup()
        delay()
        let vc = ConfirmMnemonicViewController()
        newSafeFlowCoordinator.paperWalletFlowCoordinator.confirmMnemonicViewControllerDidConfirm(vc)
        delay()
        XCTAssertTrue(topViewController === startVC)
    }

    func test_whenCancellationAlertConfirmed_thenPopsBackToNewSafeScreen() {
        let newSafeFlowCoordinator = TestableNewSafeFlowCoordinator(rootViewController: UINavigationController())
        newSafeFlowCoordinator.setUp()
        walletService.createReadyToDeployWallet()
        walletService.expect_deployWallet()
        newSafeFlowCoordinator.rootViewController.loadViewIfNeeded()
        newSafeFlowCoordinator.didSelectNext()
        newSafeFlowCoordinator.deploymentDidCancel()
        let alert = newSafeFlowCoordinator.modallyPresentedController as! UIAlertController
        guard let confirmCancellationAction = alert.actions.first(where: { $0.style == .destructive }) else {
            XCTFail("Confirm cancellation action not found")
            return
        }
        walletService.expect_abortDeployment()
        confirmCancellationAction.test_handler?(confirmCancellationAction)
        XCTAssertTrue(walletService.verifyAborted())
        XCTAssertNil(newSafeFlowCoordinator.modallyPresentedController)
        XCTAssertTrue(newSafeFlowCoordinator.didPopToCheckpoint)
    }

    func test_whenCancellationAlertDismissed_thenStaysOnPendingController() {
        walletService.createReadyToDeployWallet()
        let newSafeFlowCoordinator = TestableNewSafeFlowCoordinator(rootViewController: UINavigationController())
        newSafeFlowCoordinator.setUp()
        newSafeFlowCoordinator.deploymentDidCancel()
        let alert = newSafeFlowCoordinator.modallyPresentedController as! UIAlertController
        guard let action = alert.actions.first(where: { $0.style == .cancel }) else {
            XCTFail("Confirm cancellation action not found")
            return
        }
        newSafeFlowCoordinator.didPush = false
        action.test_handler?(action)
        XCTAssertNil(newSafeFlowCoordinator.modallyPresentedController)
        XCTAssertFalse(newSafeFlowCoordinator.didPush)
    }

    func test_whenDeploymentSuccess_thenExitsFlow() {
        let testFC = TestFlowCoordinator()
        var finished = false
        testFC.enter(flow: newSafeFlowCoordinator) {
            finished = true
        }
        newSafeFlowCoordinator.deploymentDidSuccess()
        XCTAssertTrue(finished)
    }

    func test_whenDeploymentFailed_thenShowsAlertThatTakesBackToNewSafeScreen() {
        walletService.createReadyToDeployWallet()
        let newSafeFlowCoordinator = TestableNewSafeFlowCoordinator(rootViewController: UINavigationController())
        newSafeFlowCoordinator.setUp()
        newSafeFlowCoordinator.deploymentDidFail("")
        guard let alert = newSafeFlowCoordinator.modallyPresentedController as? UIAlertController,
            let action = alert.actions.first(where: { $0.style == .cancel }) else {
                XCTFail("Confirm cancellation action not found")
                return
        }
        action.test_handler?(action)
        XCTAssertNil(newSafeFlowCoordinator.modallyPresentedController)
        XCTAssertTrue(newSafeFlowCoordinator.didPopToCheckpoint)
    }

    func test_whenSafeIsInAnyPendingState_thenShowingPendingController() {
        walletService.expect_isSafeCreationInProgress(true)
        assertShowingPendingVC()

        walletService.expect_isSafeCreationInProgress(false)
        assertShowingPendingVC(shouldShow: false)
    }

    func test_tracking() {
        let screenEvent = newSafeFlowCoordinator.newPairController().screenTrackingEvent as? OnboardingTrackingEvent
        XCTAssertEqual(screenEvent, .twoFA)

        let scanEvent = newSafeFlowCoordinator.newPairController().scanTrackingEvent as? OnboardingTrackingEvent
        XCTAssertEqual(scanEvent, .twoFAScan)
    }

}

private extension NewSafeFlowCoordinatorTests {

    func deploy() {
        walletService.deployWallet(subscriber: MockEventSubscriber(), onError: nil)
    }

    func assertShowingPendingVC(shouldShow: Bool = true, line: UInt = #line) {
        let testFC = TestFlowCoordinator()
        testFC.enter(flow: newSafeFlowCoordinator)
        delay()
        XCTAssertTrue((testFC.topViewController is SafeCreationViewController) == shouldShow,
                      "\(String(describing: testFC.topViewController)) is not PendingViewController",
                      line: line)
    }

    func pairWithBrowserExtension() {
        ethereumService.browserExtensionAddress = "code"
        walletService.expect_isSafeCreationInProgress(true)
        startVC = topViewController
        newSafeFlowCoordinator.didSelectBrowserExtensionSetup()
        delay()
        pairVC = topViewController as? PairWithBrowserExtensionViewController
        pairVC!.loadViewIfNeeded()
        pairVC!.scanBarButtonItemDidScanValidCode("code")
        delay()
    }

}

class MockEventSubscriber: EventSubscriber {
    func notify() {}
}

class TestableNewSafeFlowCoordinator: NewSafeFlowCoordinator {

    var modallyPresentedController: UIViewController?

    override func presentModally(_ controller: UIViewController) {
        modallyPresentedController = controller
    }

    override func dismissModal(_ completion: (() -> Void)?) {
        modallyPresentedController = nil
    }

    var didPush: Bool = false

    override func push(_ controller: UIViewController, onPop action: (() -> Void)?) {
        didPush = true
    }

    var didPopToCheckpoint: Bool = false

    override func popToLastCheckpoint() {
        didPopToCheckpoint = true
    }

}
