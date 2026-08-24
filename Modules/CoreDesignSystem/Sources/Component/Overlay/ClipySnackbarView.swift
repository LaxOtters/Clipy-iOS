//
//  ClipySnackbarView.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import UIKit

/// 화면 상단에 잠시 보여주는 Snackbar입니다.
/// 본문 탭은 닫기만 요청하고, action 버튼은 해당 action만 실행합니다.
@MainActor
public final class ClipySnackbarView: UIControl {
    private enum LayoutMode {
        case contentOnly
        case horizontalAction
        case verticalAction
    }

    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let onDismiss: () -> Void
    private var layoutMode: LayoutMode?
    private var activeLayoutConstraints: [NSLayoutConstraint] = []

    public init(
        message: String,
        action: ClipySnackbar.Action?,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        configureBackground()
        configureContent(message: message, action: action)
        updateLayoutMode(for: 349)
        addTarget(self, action: #selector(didTapBody), for: .touchUpInside)
    }

    public override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let fittingWidth = targetSize.width.isFinite && targetSize.width > 0
            ? targetSize.width
            : (bounds.width > 0 ? bounds.width : 349)
        updateLayoutMode(for: fittingWidth)

        return super.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    public override func layoutSubviews() {
        updateLayoutMode(for: bounds.width)
        super.layoutSubviews()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipySnackbarView {
    var messageSingleLineWidth: CGFloat {
        ceil(messageLabel.attributedText?.size().width ?? 0)
    }

    var messageContainsExplicitLineBreak: Bool {
        messageLabel.attributedText?.string.rangeOfCharacter(from: .newlines) != nil
    }

    func configureBackground() {
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 4

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 8
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        let tintView = UIView()
        tintView.backgroundColor = ClipyColor.Foundation.alphaBlack60
        tintView.clipsToBounds = true
        tintView.layer.cornerRadius = 8
        tintView.isUserInteractionEnabled = false
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configureContent(message: String, action: ClipySnackbar.Action?) {
        messageLabel.numberOfLines = 0
        messageLabel.isUserInteractionEnabled = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        ClipyTypography.body1Medium.apply(
            to: messageLabel,
            text: message,
            color: ClipyColor.Foundation.primary50
        )
        addSubview(messageLabel)

        actionButton.contentHorizontalAlignment = .trailing
        actionButton.configuration = .plain()
        actionButton.configuration?.titleLineBreakMode = .byTruncatingTail
        actionButton.titleLabel?.numberOfLines = 1
        actionButton.titleLabel?.lineBreakMode = .byTruncatingTail
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        if let action {
            actionButton.setAttributedTitle(
                ClipyTypography.body1SemiBold.attributedString(
                    action.title,
                    color: ClipyColor.Foundation.primary300,
                    alignment: .right,
                    lineBreakMode: .byTruncatingTail
                ),
                for: .normal
            )
            actionButton.addAction(
                UIAction { _ in action.handler() },
                for: .touchUpInside
            )
            addSubview(actionButton)
        } else {
            actionButton.isHidden = true
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: 349)
        ])

        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        actionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    func updateLayoutMode(for width: CGFloat) {
        let nextMode = resolvedLayoutMode(for: width)
        guard nextMode != layoutMode else { return }

        NSLayoutConstraint.deactivate(activeLayoutConstraints)
        layoutMode = nextMode
        activeLayoutConstraints = constraints(for: nextMode)
        NSLayoutConstraint.activate(activeLayoutConstraints)
    }

    private func constraints(for mode: LayoutMode) -> [NSLayoutConstraint] {
        switch mode {
        case .contentOnly:
            messageLabel.numberOfLines = 0
            return [
                messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
            ]

        case .horizontalAction:
            messageLabel.numberOfLines = 1
            actionButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
                top: 12,
                leading: 12,
                bottom: 12,
                trailing: 16
            )
            return [
                messageLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
                messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor),
                messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
                messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                actionButton.topAnchor.constraint(equalTo: topAnchor),
                actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
                actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ]

        case .verticalAction:
            messageLabel.numberOfLines = 0
            actionButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
                top: 8,
                leading: 12,
                bottom: 12,
                trailing: 16
            )
            return [
                messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor),
                actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
                actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
                actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ]
        }
    }

    private func resolvedLayoutMode(for width: CGFloat) -> LayoutMode {
        guard !actionButton.isHidden else { return .contentOnly }
        guard width > 0 else { return layoutMode ?? .horizontalAction }

        let actionWidth = max(44, actionButton.intrinsicContentSize.width)
        let requiredWidth = 16 + messageSingleLineWidth + actionWidth
        return messageContainsExplicitLineBreak || requiredWidth > width
            ? .verticalAction
            : .horizontalAction
    }

    @objc func didTapBody() {
        onDismiss()
    }
}
