//
//  ClipyTextView.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

/// 여러 줄 입력 칸입니다. 한 줄 입력 칸과 같은 테두리·포커스 모양을 쓰고, 비어 있을 때 안내 문구를 보여 줍니다.
/// delegate는 비워 두어, 화면이 `UITextView`의 기본 이벤트를 그대로 쓸 수 있게 합니다.
public final class ClipyTextView: UITextView {
    enum Layout {
        static let contentInsets = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
    }

    public var placeholder: String? {
        get { placeholderLabel.text }
        set {
            placeholderLabel.text = newValue
            renderPlaceholder()
        }
    }

    public override var text: String! {
        didSet {
            renderPlaceholder()
        }
    }

    private let placeholderLabel = UILabel()

    public init(placeholder: String? = nil) {
        super.init(frame: .zero, textContainer: nil)
        font = ClipyTypography.body1Regular.font
        textColor = ClipyColor.Foundation.neutral900
        backgroundColor = ClipyColor.Foundation.primary50
        textContainerInset = Layout.contentInsets
        layer.cornerRadius = ClipyTextField.Layout.cornerRadius
        layer.borderWidth = ClipyTextField.Layout.borderWidth

        placeholderLabel.font = ClipyTypography.body1Regular.font
        placeholderLabel.textColor = ClipyColor.Foundation.neutral400
        placeholderLabel.numberOfLines = 0
        addSubview(placeholderLabel)
        self.placeholder = placeholder

        // delegate를 쓰지 않고 변경 알림으로 안내 문구를 갱신합니다.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        updateAppearance()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalInset = textContainerInset.left + textContainer.lineFragmentPadding
        let width = bounds.width - horizontalInset - textContainerInset.right - textContainer.lineFragmentPadding
        let height = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        placeholderLabel.frame = CGRect(x: horizontalInset, y: textContainerInset.top, width: width, height: height)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        updateAppearance()
        return didBecome
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        updateAppearance()
        return didResign
    }

    @objc
    private func textDidChange() {
        renderPlaceholder()
    }

    private func renderPlaceholder() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    private func updateAppearance() {
        layer.borderColor = (isFirstResponder
            ? ClipyColor.Foundation.neutral800
            : ClipyColor.Foundation.neutral200).cgColor
    }
}
