//
//  HomeHeroView.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import CoreDesignSystem

/// 새 Session 시작 action을 강조하는 First Use 전용 hero입니다.
final class HomeHeroView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(button: HomeHeroButton) {
        super.init(frame: .zero)

        layer.cornerRadius = 16
        clipsToBounds = true
        gradientLayer.cornerRadius = 16
        layer.insertSublayer(gradientLayer, at: 0)

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        ClipyTypography.heading1.apply(
            to: titleLabel,
            text: "Start New Session",
            color: ClipyColor.Foundation.primary50
        )

        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        ClipyTypography.body2Medium.apply(
            to: descriptionLabel,
            text: "Compare products without losing context.",
            color: ClipyColor.Foundation.alphaWhite70
        )

        let contentStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, button])
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = 8
        contentStackView.setCustomSpacing(18, after: descriptionLabel)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -32),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        ClipyGradient.Foundation.linearMint.apply(to: gradientLayer)
    }
}
