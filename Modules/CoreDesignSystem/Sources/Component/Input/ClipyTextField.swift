//
//  ClipyTextField.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

/// 한 줄 입력 칸입니다. 입력 중이면 테두리를 진하게 바꿉니다.
/// 이벤트와 값은 `UITextField`가 가진 것을 그대로 쓰고, 오른쪽 부가 요소는 `rightView`로 붙입니다.
public final class ClipyTextField: UITextField {
    enum Layout {
        static let height: CGFloat = 48
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let horizontalInset: CGFloat = 16
        static let leadingIconSize: CGFloat = 20
        static let leadingIconSpacing: CGFloat = 8
        static let trailingViewInset: CGFloat = 8
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Layout.height)
    }

    public override var placeholder: String? {
        get { attributedPlaceholder?.string }
        set {
            attributedPlaceholder = newValue.map {
                NSAttributedString(
                    string: $0,
                    attributes: [
                        .font: ClipyTypography.body1Regular.font,
                        .foregroundColor: ClipyColor.Foundation.neutral400
                    ]
                )
            }
        }
    }

    /// leadingIcon은 template 이미지로 그려 입력 칸 색에 맞춥니다.
    public init(leadingIcon: UIImage? = nil) {
        super.init(frame: .zero)
        font = ClipyTypography.body1Regular.font
        textColor = ClipyColor.Foundation.neutral900
        backgroundColor = ClipyColor.Foundation.primary50
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = Layout.borderWidth

        if let leadingIcon {
            let iconView = UIImageView(image: leadingIcon.withRenderingMode(.alwaysTemplate))
            iconView.tintColor = ClipyColor.Foundation.neutral600
            iconView.contentMode = .scaleAspectFit
            leftView = iconView
            leftViewMode = .always
        }

        updateAppearance()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets(for: bounds))
    }

    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets(for: bounds))
    }

    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets(for: bounds))
    }

    public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: Layout.horizontalInset,
            y: (bounds.height - Layout.leadingIconSize) / 2,
            width: Layout.leadingIconSize,
            height: Layout.leadingIconSize
        )
    }

    public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let size = trailingViewSize(in: bounds)
        return CGRect(
            x: bounds.maxX - Layout.trailingViewInset - size.width,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func textInsets(for bounds: CGRect) -> UIEdgeInsets {
        let leading = Layout.horizontalInset
            + (leftView == nil ? 0 : Layout.leadingIconSize + Layout.leadingIconSpacing)
        let trailingViewWidth = trailingViewSize(in: bounds).width
        let trailing = trailingViewWidth > 0
            ? Layout.trailingViewInset + trailingViewWidth + Layout.leadingIconSpacing
            : Layout.horizontalInset
        return UIEdgeInsets(top: 0, left: leading, bottom: 0, right: trailing)
    }

    private func trailingViewSize(in bounds: CGRect) -> CGSize {
        guard let rightView, rightViewMode != .never else {
            return .zero
        }

        let fitting = rightView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fitting.width, height: min(fitting.height, bounds.height))
    }

    // 포커스 여부는 first responder로만 판단해, 입력 칸 밖에 같은 상태를 따로 두지 않습니다.
    private func updateAppearance() {
        layer.borderColor = (isFirstResponder
            ? ClipyColor.Foundation.neutral800
            : ClipyColor.Foundation.neutral200).cgColor
    }
}
