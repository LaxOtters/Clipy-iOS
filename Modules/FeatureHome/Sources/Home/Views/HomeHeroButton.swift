//
//  HomeHeroButton.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import CoreDesignSystem

/// Hero 안에서만 쓰는 반투명 CTA입니다. 공용 버튼 variant로 올리지 않습니다.
final class HomeHeroButton: UIButton {
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    private let titleLabelView = UILabel()
    private let arrowImageView = UIImageView()

    init() {
        super.init(frame: .zero)

        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = ClipyColor.Foundation.alphaWhite20.cgColor

        ClipyTypography.body3SemiBold.apply(
            to: titleLabelView,
            text: "Begin Comparison",
            color: ClipyColor.Foundation.primary50
        )
        arrowImageView.image = ClipyIcon.rightArrow
        arrowImageView.tintColor = ClipyColor.Foundation.primary50
        arrowImageView.contentMode = .center

        let contentStackView = UIStackView(arrangedSubviews: [titleLabelView, arrowImageView])
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 6
        contentStackView.isUserInteractionEnabled = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 14),
            arrowImageView.heightAnchor.constraint(equalToConstant: 14)
        ])

        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func updateAppearance() {
        backgroundColor = isEnabled
            ? ClipyColor.Foundation.alphaWhite20
            : ClipyColor.Foundation.alphaWhite10
        alpha = isEnabled ? 1 : 0.7
    }
}
