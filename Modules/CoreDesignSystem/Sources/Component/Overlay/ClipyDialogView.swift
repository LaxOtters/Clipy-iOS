//
//  ClipyDialogView.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import UIKit

/// `ClipyDialog.Configuration`에 맞춰 Dialog 카드를 그립니다.
/// Prompt Dialog은 버튼을 누른 순간의 입력값도 함께 넘깁니다.
@MainActor
public final class ClipyDialogView: UIView {
    private let configuration: ClipyDialog.Configuration
    private let onSelection: (ClipyDialog.Selection, String?) -> Void
    private var promptTextField: UITextField?

    public init(
        configuration: ClipyDialog.Configuration,
        onSelection: @escaping (ClipyDialog.Selection, String?) -> Void
    ) {
        self.configuration = configuration
        self.onSelection = onSelection
        super.init(frame: .zero)

        configureAppearance()
        configureContent()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipyDialogView {
    func configureAppearance() {
        backgroundColor = ClipyColor.Foundation.primary50
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 10
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    }

    func configureContent() {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let presentationAndTextStack = UIStackView()
        presentationAndTextStack.axis = .vertical
        presentationAndTextStack.alignment = .fill
        presentationAndTextStack.spacing = presentationSpacing

        if let presentationView = makePresentationView() {
            presentationAndTextStack.addArrangedSubview(presentationView)
        }
        presentationAndTextStack.addArrangedSubview(makeTextContent())

        let detailsStack = UIStackView(arrangedSubviews: [presentationAndTextStack])
        detailsStack.axis = .vertical
        detailsStack.alignment = .fill
        detailsStack.spacing = 20
        if let textField = makePromptTextField() {
            detailsStack.addArrangedSubview(textField)
            promptTextField = textField
        }

        detailsStack.translatesAutoresizingMaskIntoConstraints = false

        let detailsScrollView = UIScrollView()
        detailsScrollView.alwaysBounceVertical = false
        detailsScrollView.showsVerticalScrollIndicator = true
        detailsScrollView.addSubview(detailsStack)

        let naturalDetailsHeight = detailsScrollView.heightAnchor.constraint(equalTo: detailsStack.heightAnchor)
        naturalDetailsHeight.priority = UILayoutPriority(749)
        NSLayoutConstraint.activate([
            detailsStack.topAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.topAnchor),
            detailsStack.leadingAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.leadingAnchor),
            detailsStack.trailingAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.trailingAnchor),
            detailsStack.bottomAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.bottomAnchor),
            detailsStack.widthAnchor.constraint(equalTo: detailsScrollView.frameLayoutGuide.widthAnchor),
            naturalDetailsHeight
        ])

        contentStack.addArrangedSubview(detailsScrollView)
        contentStack.addArrangedSubview(makeButtons())
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            widthAnchor.constraint(lessThanOrEqualToConstant: 384)
        ])
    }

    var presentationSpacing: CGFloat {
        switch configuration.presentation {
        case .plain:
            0
        case .semanticIcon:
            4
        case .websiteRequest:
            20
        }
    }

    func makePresentationView() -> UIView? {
        switch configuration.presentation {
        case .plain:
            return nil
        case .semanticIcon(.error):
            guard let image = CoreDesignSystemImage.errorRounded else {
                return nil
            }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 60)
            ])
            let container = UIStackView(arrangedSubviews: [imageView])
            container.alignment = .center
            return container
        case let .websiteRequest(sourceText):
            let sourceLabel = UILabel()
            sourceLabel.numberOfLines = 1
            sourceLabel.lineBreakMode = .byTruncatingTail
            ClipyTypography.body1Medium.apply(
                to: sourceLabel,
                text: sourceText,
                color: ClipyColor.Foundation.neutral700
            )

            var arrangedSubviews: [UIView] = []
            if let image = CoreDesignSystemImage.dialogRequestSource {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false

                let imageContainer = UIView()
                imageContainer.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageContainer.widthAnchor.constraint(equalToConstant: 24),
                    imageContainer.heightAnchor.constraint(equalToConstant: 24),
                    imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 24),
                    imageView.heightAnchor.constraint(equalToConstant: 24)
                ])
                arrangedSubviews.append(imageContainer)
            }
            arrangedSubviews.append(sourceLabel)

            let stack = UIStackView(arrangedSubviews: arrangedSubviews)
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 6
            return stack
        }
    }

    func makeTextContent() -> UIView {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        ClipyTypography.heading2.apply(
            to: titleLabel,
            text: configuration.title,
            color: ClipyColor.Foundation.neutral800
        )

        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        ClipyTypography.body1Regular.apply(
            to: bodyLabel,
            text: configuration.body,
            color: ClipyColor.Foundation.neutral500
        )

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }

    func makePromptTextField() -> UITextField? {
        guard case let .prompt(_, _, _, initialText, placeholder, _, _) = configuration else {
            return nil
        }

        let textField = UITextField()
        textField.text = initialText
        textField.placeholder = placeholder
        textField.font = ClipyTypography.body1Regular.font
        textField.textColor = ClipyColor.Foundation.neutral800
        textField.backgroundColor = ClipyColor.Foundation.primary50
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = ClipyColor.Foundation.neutral200.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.rightViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }

    func makeButtons() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 12

        switch configuration {
        case let .message(_, _, _, buttons):
            switch buttons {
            case let .single(title):
                stack.addArrangedSubview(makeButton(title: title, selection: .single, isPrimary: true))
            case let .dual(primaryTitle, secondaryTitle):
                stack.addArrangedSubview(makeButton(title: secondaryTitle, selection: .secondary, isPrimary: false))
                stack.addArrangedSubview(makeButton(title: primaryTitle, selection: .primary, isPrimary: true))
            }
        case let .prompt(_, _, _, _, _, primaryTitle, secondaryTitle):
            stack.addArrangedSubview(makeButton(title: secondaryTitle, selection: .secondary, isPrimary: false))
            stack.addArrangedSubview(makeButton(title: primaryTitle, selection: .primary, isPrimary: true))
        }

        return stack
    }

    func makeButton(
        title: String,
        selection: ClipyDialog.Selection,
        isPrimary: Bool
    ) -> ClipyButton {
        let button: ClipyButton
        if isPrimary, configuration.presentation.isWebsiteRequest {
            button = ClipyButton(
                variant: .primaryMedium,
                title: title,
                colorRole: .primary500
            )
        } else {
            button = ClipyButton(
                variant: isPrimary ? .primaryMedium : .secondaryMedium,
                title: title
            )
        }
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onSelection(selection, self.promptTextField?.text)
        }, for: .touchUpInside)
        return button
    }
}

private extension ClipyDialog.Configuration {
    var presentation: ClipyDialog.Presentation {
        switch self {
        case let .message(presentation, _, _, _), let .prompt(presentation, _, _, _, _, _, _):
            return presentation
        }
    }

    var title: String {
        switch self {
        case let .message(_, title, _, _), let .prompt(_, title, _, _, _, _, _):
            return title
        }
    }

    var body: String {
        switch self {
        case let .message(_, _, body, _), let .prompt(_, _, body, _, _, _, _):
            return body
        }
    }
}

private extension ClipyDialog.Presentation {
    var isWebsiteRequest: Bool {
        if case .websiteRequest = self {
            return true
        }
        return false
    }
}
