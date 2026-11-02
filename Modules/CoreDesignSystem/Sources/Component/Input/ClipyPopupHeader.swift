//
//  ClipyPopupHeader.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

/// 팝업 카드 상단의 닫기 버튼, 제목, 오른쪽 동작 버튼입니다.
/// 버튼은 control 그대로 열어, 화면이 탭 이벤트를 묶고 동작 버튼의 활성 여부를 정합니다.
public final class ClipyPopupHeader: UIView {
    enum Layout {
        static let height: CGFloat = 60
        static let horizontalInset: CGFloat = 20
        static let closeIconSize: CGFloat = 24
        static let titleSpacing: CGFloat = 16
        static let actionButtonWidth: CGFloat = 72
    }

    public let closeButton = UIButton(type: .system)
    /// actionTitle 없이 만들면 nil입니다.
    public let actionButton: ClipyButton?

    private let titleLabel = UILabel()

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Layout.height)
    }

    public init(title: String, actionTitle: String? = nil) {
        actionButton = actionTitle.map { ClipyButton(variant: .primarySmall, title: $0) }
        super.init(frame: .zero)

        closeButton.setImage(
            UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            ),
            for: .normal
        )
        closeButton.tintColor = ClipyColor.Foundation.neutral600
        titleLabel.attributedText = ClipyTypography.heading3.attributedString(
            title,
            color: ClipyColor.Foundation.neutral900
        )
        configureLayout()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        [closeButton, titleLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Layout.closeIconSize),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.closeIconSize),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: Layout.titleSpacing),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        guard let actionButton else {
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -Layout.horizontalInset
            ).isActive = true
            return
        }

        addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: Layout.actionButtonWidth),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: actionButton.leadingAnchor,
                constant: -Layout.titleSpacing
            )
        ])
    }
}
