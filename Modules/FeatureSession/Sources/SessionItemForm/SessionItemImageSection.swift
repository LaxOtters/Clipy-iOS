//
//  SessionItemImageSection.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import CoreDesignSystem

/// 상품 이미지 영역입니다. 사진을 고르는 동작이 붙기 전까지 placeholder만 보이고 눌러도 반응하지 않습니다.
final class SessionItemImageSection: UIView {
    private enum Layout {
        static let size: CGFloat = 200
        static let cornerRadius: CGFloat = 12
    }

    private let placeholderView = UIImageView()

    override var intrinsicContentSize: CGSize {
        CGSize(width: Layout.size, height: Layout.size)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ClipyColor.Foundation.neutral100
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        placeholderView.image = UIImage(systemName: "photo")
        placeholderView.tintColor = ClipyColor.Foundation.neutral400
        placeholderView.contentMode = .center
        addSubview(placeholderView)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
