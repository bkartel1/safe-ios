//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public extension GuidelinesViewController {

    private enum Strings {
        static let title = LocalizedString("recover_safe_title", comment: "Recover safe")
        static let header = LocalizedString("how_this_works", comment: "How this works")
        static let body = LocalizedString("ios_recovery_intro_content",
                                          comment: "Content paragraphs, separated by '\n'")
        static let start = LocalizedString("start", comment: "Start button title")
    }

    static func createRecoverSafeGuidelines(delegate: GuidelinesViewControllerDelegate? = nil)
        -> GuidelinesViewController {
            let controller = GuidelinesViewController.create(delegate: delegate)
            controller.titleText = Strings.title
            controller.headerText = Strings.header
            controller.headerImage = Asset.Onboarding.safeInprogress.image
            controller.bodyText = Strings.body
            controller.nextActionText = Strings.start
            return controller
    }

}
