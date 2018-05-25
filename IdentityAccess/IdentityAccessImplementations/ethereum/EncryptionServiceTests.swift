//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import IdentityAccessImplementations
import IdentityAccessDomainModel

class EncryptionServiceTests: XCTestCase {

    let service = EthereumKitEncryptionService()

    func test_encryption() {
        XCTAssertNotEqual(service.encrypted("text"), "text")
    }

}
