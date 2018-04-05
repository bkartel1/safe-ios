//
//  Copyright © 2018 Gnosis. All rights reserved.
//

import XCTest
@testable import safe

class OnboardingFlowCoordinatorTests: AbstractAppTestCase {

    var flowCoordinator = OnboardingFlowCoordinator()

    func test_startViewController_whenNoMasterPassword_thenMasterPasswordFlowStarted() {
        account.hasMasterPassword = false
        let startVC = flowCoordinator.startViewController()
        let masterPasswordVC = flowCoordinator.masterPasswordFlowCoordinator.startViewController()
        XCTAssertTrue(type(of: startVC) == type(of: masterPasswordVC))
    }

    func test_startViewController_whenMasterPasswordIsSet_thenNewSafeFlowStarted() {
        account.hasMasterPassword = true
        let startVC = flowCoordinator.startViewController()
        let setupSafeVC = flowCoordinator.setupSafeFlowCoordinator.startViewController()
        XCTAssertTrue(type(of: startVC) == type(of: setupSafeVC))
    }

}
