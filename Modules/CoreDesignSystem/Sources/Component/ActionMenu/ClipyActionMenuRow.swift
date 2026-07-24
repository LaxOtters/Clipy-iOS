//
//  ClipyActionMenuRow.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit

final class ClipyActionMenuRow: UIControl {
    init(item: ClipyActionMenuItem) {
        super.init(frame: .zero)

        let tintColor: UIColor
        switch item.role {
        case .normal:
            tintColor = ClipyColor.Foundation.neutral600
        case .destructive:
            tintColor = ClipyColor.Foundation.error700
        }

        let imageView = UIImageView(image: item.image)
        imageView.tintColor = tintColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ClipyTypography.body2Medium.apply(
            to: titleLabel,
            text: item.title,
            color: item.role == .normal ? ClipyColor.Foundation.neutral800 : ClipyColor.Foundation.error700
        )

        addSubview(imageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
