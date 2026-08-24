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
    private let messageLabel = UILabel()
    private let actionButton = SnackbarActionButton(type: .system)
    private let contentStack = UIStackView()
    private let onDismiss: () -> Void
    private lazy var messageVerticalWidthConstraint = messageLabel.widthAnchor.constraint(
        equalTo: contentStack.widthAnchor
    )

    public init(
        message: String,
        action: ClipySnackbar.Action?,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        configureBackground()
        configureContent(message: message, action: action)
        addTarget(self, action: #selector(didTapBody), for: .touchUpInside)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard !actionButton.isHidden else {
            messageVerticalWidthConstraint.isActive = false
            contentStack.axis = .horizontal
            contentStack.alignment = .center
            return
        }

        let availableWidth = max(bounds.width - 32, 0)
        let requiredWidth = messageSingleLineWidth
            + actionButton.intrinsicContentSize.width
            + 12
        let usesVerticalLayout = messageContainsExplicitLineBreak
            || requiredWidth > availableWidth
        messageVerticalWidthConstraint.isActive = usesVerticalLayout
        messageLabel.numberOfLines = usesVerticalLayout ? 0 : 1
        contentStack.axis = usesVerticalLayout ? .vertical : .horizontal
        contentStack.alignment = usesVerticalLayout ? .trailing : .center
        contentStack.spacing = usesVerticalLayout ? 8 : 12
        contentStack.layoutIfNeeded()
        actionButton.updateHitArea(
            maximumTopExpansion: usesVerticalLayout ? contentStack.spacing : nil
        )
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled,
              !isHidden,
              alpha > 0.01,
              self.point(inside: point, with: event) else {
            return nil
        }

        let actionPoint = actionButton.convert(point, from: self)
        // 버튼 영역을 먼저 넘겨서 body dismiss와 action이 같이 실행되지 않게 합니다.
        if !actionButton.isHidden,
           let actionTarget = actionButton.hitTest(actionPoint, with: event) {
            return actionTarget
        }

        return self
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
        clipsToBounds = false
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
        ClipyTypography.body1Medium.apply(
            to: messageLabel,
            text: message,
            color: ClipyColor.Foundation.primary50
        )

        actionButton.contentHorizontalAlignment = .trailing
        actionButton.configuration = .plain()
        actionButton.configuration?.contentInsets = .zero
        actionButton.configuration?.titleLineBreakMode = .byTruncatingTail
        actionButton.titleLabel?.numberOfLines = 1
        actionButton.titleLabel?.lineBreakMode = .byTruncatingTail

        if let action {
            actionButton.isHidden = false
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
        } else {
            actionButton.isHidden = true
        }

        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(actionButton)
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            widthAnchor.constraint(lessThanOrEqualToConstant: 349),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: contentStack.widthAnchor)
        ])

        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        actionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    @objc func didTapBody() {
        onDismiss()
    }
}

private final class SnackbarActionButton: UIButton {
    private let minimumHitSize = CGSize(width: 44, height: 44)
    private var hitAreaInsets = UIEdgeInsets.zero

    func updateHitArea(maximumTopExpansion: CGFloat?) {
        let horizontalExpansion = max((minimumHitSize.width - bounds.width) / 2, 0)
        let requiredVerticalExpansion = max(minimumHitSize.height - bounds.height, 0)
        let centeredTopExpansion = requiredVerticalExpansion / 2
        let topExpansion = min(maximumTopExpansion ?? centeredTopExpansion, centeredTopExpansion)
        let bottomExpansion = requiredVerticalExpansion - topExpansion

        hitAreaInsets = UIEdgeInsets(
            top: -topExpansion,
            left: -horizontalExpansion,
            bottom: -bottomExpansion,
            right: -horizontalExpansion
        )
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isUserInteractionEnabled,
              !isHidden,
              alpha > 0.01 else {
            return false
        }

        // 세로 배치에서는 메시지 쪽 확장을 간격 안으로 제한하고, 남은 영역은 아래 여백을 사용합니다.
        return bounds.inset(by: hitAreaInsets).contains(point)
    }
}
