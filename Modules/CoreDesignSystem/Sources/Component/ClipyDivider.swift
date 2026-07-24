//
//  ClipyDivider.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit

/// 콘텐츠 영역 사이를 구분하고 필요한 세로 여백을 함께 제공합니다.
/// 가로 길이는 이 뷰를 사용하는 화면이 정합니다.
public final class ClipyDivider: UIView {
    /// 선 두께가 아니라 구분선이 차지하는 전체 세로 여백을 정합니다.
    public enum Spacing {
        case large
        case medium
        case small
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: spacing.height)
    }

    private let spacing: Spacing
    private let lineView = UIView()

    public init(spacing: Spacing) {
        self.spacing = spacing
        super.init(frame: .zero)

        lineView.backgroundColor = ClipyColor.Foundation.neutral100
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)

        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.centerYAnchor.constraint(equalTo: centerYAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 1.5)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipyDivider.Spacing {
    var height: CGFloat {
        switch self {
        case .large:
            40
        case .medium:
            20
        case .small:
            10
        }
    }
}
