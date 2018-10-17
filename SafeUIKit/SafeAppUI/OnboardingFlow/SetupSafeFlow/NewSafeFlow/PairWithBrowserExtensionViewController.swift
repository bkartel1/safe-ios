//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import IdentityAccessApplication
import MultisigWalletApplication
import MultisigWalletApplication
import Common

protocol PairWithBrowserDelegate: class {
    func didPair()
}

final class PairWithBrowserExtensionViewController: UIViewController {

    enum Strings {

        static let save = LocalizedString("new_safe.extension.save",
                                          comment: "Save button title in extension setup screen")
        static let update = LocalizedString("new_safe.extension.update",
                                            comment: "Update button title in extension setup screen")
        static let browserExtensionExpired = LocalizedString("new_safe.extension.expired",
                                                             comment: "Browser Extension Expired Message")
        static let networkError = LocalizedString("new_safe.extension.network_error", comment: "Network error message")
        static let invalidCode = LocalizedString("new_safe.extension.invalid_code_error",
                                                 comment: "Invalid extension code")

    }

    @IBOutlet weak var titleLabel: H1Label!
    @IBOutlet weak var extensionAddressInput: QRCodeInput!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private(set) weak var delegate: PairWithBrowserDelegate?
    private var logger: Logger {
        return MultisigWalletApplication.ApplicationServiceRegistry.logger
    }
    private var walletService: WalletApplicationService {
        return MultisigWalletApplication.ApplicationServiceRegistry.walletService
    }
    private var ethereumService: EthereumApplicationService {
        return MultisigWalletApplication.ApplicationServiceRegistry.ethereumService
    }

    private var scannedCode: String?

    static func create(delegate: PairWithBrowserDelegate) -> PairWithBrowserExtensionViewController {
        let controller = StoryboardScene.NewSafe.pairWithBrowserExtensionViewController.instantiate()
        controller.delegate = delegate
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBrowserExtensionInput()
        configureSaveButton()
        addDebugButtons()
    }

    private func configureBrowserExtensionInput() {
        extensionAddressInput.text = walletService.ownerAddress(of: .browserExtension)
        extensionAddressInput.editingMode = .scanOnly
        extensionAddressInput.qrCodeDelegate = self
        extensionAddressInput.scanValidatedConverter = ethereumService.address(browserExtensionCode:)
    }

    private func configureSaveButton() {
        let buttonTitle = walletService.isOwnerExists(.browserExtension) ? Strings.update : Strings.save
        saveButton.setTitle(buttonTitle, for: .normal)
        saveButton.isEnabled = false
    }

    @IBAction func finish(_ sender: Any) {
        guard let text = extensionAddressInput.text, !text.isEmpty else {
            logger.error("Wrong state in PairWithBrowserExtensionViewController.")
            return
        }
        saveButton.isEnabled = false
        activityIndicator.startAnimating()
        DispatchQueue.global().async { [weak self] in
            self?.addBrowserExtensionOwner(address: text)
        }
    }

    private func addBrowserExtensionOwner(address: String) {
        do {
            try walletService.addBrowserExtensionOwner(address: address, browserExtensionCode: scannedCode!)
            DispatchQueue.main.async {
                self.delegate?.didPair()
            }
        } catch WalletApplicationServiceError.validationFailed {
            showError(message: Strings.invalidCode, log: "Invalid browser extension code")
        } catch let error as WalletApplicationServiceError where error == .networkError || error == .clientError {
            showError(message: Strings.networkError, log: "Network Error in pairing")
        } catch WalletApplicationServiceError.exceededExpirationDate {
            showError(message: Strings.browserExtensionExpired, log: "Browser Extension code is expired")
        } catch let e {
            showError(message: Strings.invalidCode, log: "Failed to pair with extension: \(e)")
        }
    }

    private func showError(message: String, log: String) {
        DispatchQueue.main.async {
            self.saveButton.isEnabled = true
            self.activityIndicator.stopAnimating()
            ErrorHandler.showError(message: message, log: log, error: nil)
        }
    }

    // MARK: - Debug Buttons

    private let validCodeTemplate = """
        {
            "expirationDate" : "%@",
            "signature": {
                "v" : 27,
                "r" : "15823297914388465068645274956031579191506355248080856511104898257696315269079",
                "s" : "38724157826109967392954642570806414877371763764993427831319914375642632707148"
            }
        }
        """

    private func addDebugButtons() {
        extensionAddressInput.addDebugButtonToScannerController(
            title: "Scan Valid Code", scanValue: validCode(timeIntervalSinceNow: 5 * 60))
        extensionAddressInput.addDebugButtonToScannerController(
            title: "Scan Invalid Code", scanValue: "invalid_code")
        extensionAddressInput.addDebugButtonToScannerController(
            title: "Scan Expired Code", scanValue: validCode(timeIntervalSinceNow: -5 * 60))
    }

    private func validCode(timeIntervalSinceNow: TimeInterval) -> String {
        let dateStr = DateFormatter.networkDateFormatter.string(from: Date(timeIntervalSinceNow: timeIntervalSinceNow))
        return String(format: validCodeTemplate, dateStr)
    }

}

extension PairWithBrowserExtensionViewController: QRCodeInputDelegate {

    func presentController(_ controller: UIViewController) {
        present(controller, animated: true)
    }

    func didScanValidCode(_ code: String) {
        saveButton.isEnabled = true
        scannedCode = code
    }

}
