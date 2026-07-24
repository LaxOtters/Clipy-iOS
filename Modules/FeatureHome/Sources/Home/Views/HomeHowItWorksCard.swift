//
//  HomeHowItWorksCard.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import CoreDesignSystem

/// Browse, Collect, Decide 순서를 설명하는 First Use 전용 카드입니다.
final class HomeHowItWorksCard: UIView {
    enum Illustration {
        case browse
        case collect
        case decide

        var image: UIImage? {
            switch self {
            case .browse:
                return HomeAsset.browse
            case .collect:
                return HomeAsset.collect
            case .decide:
                return HomeAsset.decide
            }
        }
    }

    init(
        title: String,
        description: String,
        illustration: Illustration
    ) {
        super.init(frame: .zero)

        backgroundColor = ClipyColor.Foundation.primary50
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.06

        let titleLabel = UILabel()
        ClipyTypography.heading4.apply(
            to: titleLabel,
            text: title,
            color: ClipyColor.Foundation.neutral900
        )

        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        ClipyTypography.body2Regular.apply(
            to: descriptionLabel,
            text: description,
            color: ClipyColor.Foundation.neutral500
        )

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        let illustrationView = UIImageView(image: illustration.image)
        illustrationView.contentMode = .scaleAspectFit
        illustrationView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textStackView)
        addSubview(illustrationView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 126),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            textStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: illustrationView.leadingAnchor, constant: -12),

            illustrationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            illustrationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            illustrationView.widthAnchor.constraint(equalToConstant: 100),
            illustrationView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
