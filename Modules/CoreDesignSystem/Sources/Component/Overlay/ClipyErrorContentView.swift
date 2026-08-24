//
//  ClipyErrorContentView.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import UIKit

/// 오류 아이콘, 문구, 선택 버튼을 함께 보여주는 공용 content view입니다.
@MainActor
public final class ClipyErrorContentView: UIView {
    /// 오류 화면 버튼의 title과 누를 때 실행할 action입니다.
    public struct Action {
        public let title: String
        public let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    public init(
        title: String,
        body: String,
        action: Action? = nil
    ) {
        super.init(frame: .zero)
        configureContent(
            title: title,
            body: body,
            action: action
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipyErrorContentView {
    func configureContent(
        title: String,
        body: String,
        action: Action?
    ) {
        let imageView = UIImageView(image: CoreDesignSystemImage.errorRounded)
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70)
        ])

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        ClipyTypography.heading3.apply(
            to: titleLabel,
            text: title,
            color: ClipyColor.Foundation.neutral900
        )

        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        ClipyTypography.body1Regular.apply(
            to: bodyLabel,
            text: body,
            color: ClipyColor.Foundation.neutral900
        )

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 10

        let contentStack = UIStackView(arrangedSubviews: [imageView, textStack])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 30
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        if let action {
            addActionButton(action, to: contentStack)
        }

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
    }

    func addActionButton(_ action: Action, to contentStack: UIStackView) {
        let actionButton = ClipyButton(variant: .secondaryMedium, title: action.title)
        actionButton.addAction(UIAction { _ in action.handler() }, for: .touchUpInside)
        let fittingWidth = actionButton.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: 50)
        ).width
        contentStack.addArrangedSubview(actionButton)

        let preferredWidth = actionButton.widthAnchor.constraint(equalToConstant: max(96, fittingWidth))
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            preferredWidth
        ])
    }
}
