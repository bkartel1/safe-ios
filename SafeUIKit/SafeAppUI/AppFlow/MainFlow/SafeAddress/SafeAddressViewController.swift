//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import MultisigWalletApplication

final class SafeAddressViewController: UIViewController {

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var identiconLabel: UILabel!
    @IBOutlet weak var identiconView: IdenticonView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var safeAddressLabel: UILabel!
    @IBOutlet weak var qrCodeLabel: UILabel!
    @IBOutlet weak var qrCodeView: QRCodeView!

    enum Strings {
        static let title = LocalizedString("safe_address.title", comment: "Title for Address Details screen.")
        static let header = LocalizedString("safe_address.header", comment: "Header for Address Details screen.")
        static let description = LocalizedString("safe_address.description",
                                                 comment: "Description for Address Details screen.")
        static let identicon = LocalizedString("safe_address.identicon", comment: "Identicon label.")
        static let address = LocalizedString("safe_address.address", comment: "Safe Address label.")
        static let qrCode = LocalizedString("safe_address.qr_code", comment: "QR Code label.")
    }

    static func create() -> SafeAddressViewController {
        return StoryboardScene.Main.safeAddressViewController.instantiate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
        headerLabel.text = Strings.header
        descriptionLabel.text = Strings.description
        identiconLabel.text = Strings.identicon
        addressLabel.text = Strings.address
        qrCodeLabel.text = Strings.qrCode

        wrapperView.layer.cornerRadius = 9
        wrapperView.layer.shadowColor = UIColor.black.cgColor
        wrapperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        wrapperView.layer.shadowOpacity = 0.7

        guard let address = ApplicationServiceRegistry.walletService.selectedWalletAddress else { return }
        identiconView.seed = address

        qrCodeView.value = address
        qrCodeView.padding = 12
        qrCodeView.layer.borderWidth = 1
        qrCodeView.layer.borderColor = UIColor.black.cgColor
        qrCodeView.layer.cornerRadius = 9

        let attrStr = NSMutableAttributedString(string: address)
        attrStr.addAttribute(
            NSAttributedStringKey.foregroundColor,
            value: ColorName.blueyGrey.color,
            range: NSRange(location: 4, length: attrStr.length - 8))
        safeAddressLabel.attributedText = attrStr
    }

}
