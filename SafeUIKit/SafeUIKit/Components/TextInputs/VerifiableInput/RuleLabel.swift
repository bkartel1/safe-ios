//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit

public enum RuleStatus {

    case error
    case success
    case inactive

    var localizedDescription: String {
        switch self {
        case .error: return "error"
        case .success: return "success"
        case .inactive: return "inactive"
        }
    }

}

final class RuleLabel: UIView {

    @IBOutlet var wrapperView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    var text: String? {
        return label.text
    }

    private var rule: ((String) -> Bool)?
    private (set) var status: RuleStatus = .inactive {
        didSet {
            update()
        }
    }

    convenience init(text: String, displayIcon: Bool = false, rule: ((String) -> Bool)? = nil) {
        self.init(frame: .zero)
        self.label.text = text
        if !displayIcon {
            imageView.removeFromSuperview()
            imageView = nil
        }
        self.rule = rule
        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        loadContentsFromNib()
        backgroundColor = .clear
        wrapperView.backgroundColor = .clear
        label.textColor = ColorName.battleshipGrey.color
    }

    private func loadContentsFromNib() {
        safeUIKit_loadFromNib(forClass: RuleLabel.self)
        pinWrapperToSelf()
    }

    private func pinWrapperToSelf() {
        NSLayoutConstraint.activate([
            wrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapperView.topAnchor.constraint(equalTo: topAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
    }

    func validate(_ text: String) {
        guard let isValid = rule?(text) else { return }
        status = isValid ? .success : .error
    }

    func reset() {
        _ = rule?("") // updating rule to give chance to react rule's clients to reset() call
        status = .inactive
    }

    private func update() {
        updateImage()
        updateLabel()
    }

    private func updateImage() {
        guard imageView != nil else { return }
        switch status {
        case .error:
            imageView.image = Asset.TextInputs.errorIcon.image
        case .inactive:
            imageView.image = Asset.TextInputs.defaultIcon.image
        case .success:
            imageView.image = Asset.TextInputs.successIcon.image
        }
    }

    private func updateLabel() {
        label.accessibilityValue = [status.localizedDescription, label.text].compactMap { $0 }.joined(separator: " ")
        guard imageView == nil else { return }
        switch status {
        case .error:
            label.textColor = ColorName.tomato.color
        case .inactive:
            label.textColor = ColorName.battleshipGrey.color
        case .success:
            label.textColor = ColorName.greenTeal.color
        }
    }

}
