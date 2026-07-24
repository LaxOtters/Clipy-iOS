//
//  ClipyFooterActionButton.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit

/// 화면 하단의 주요 action을 표현하는 버튼입니다.
/// 바깥 여백과 배치는 이 버튼을 사용하는 화면이 정합니다.
public final class ClipyFooterActionButton: UIButton {
    /// 활성 상태에서 버튼이 사용할 배경 표현입니다.
    /// 비활성 상태에서는 선택한 style과 관계없이 공통 비활성 모양을 사용합니다.
    public enum Style {
        case gradient
        case solid
    }

    public override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 68)
    }

    private let style: Style
    private let gradientLayer = CAGradientLayer()

    public init(style: Style, title: String) {
        self.style = style
        super.init(frame: .zero)

        configuration = .plain()
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.1

        gradientLayer.cornerRadius = 16
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)

        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentHorizontalAlignment = .center
        super.setTitle(title, for: .normal)
        updateAppearance()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)

        if state == .normal {
            updateAppearance()
        }
    }

    public override func updateConfiguration() {
        super.updateConfiguration()
        updateAppearance()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipyFooterActionButton {
    func updateAppearance() {
        let appearance = style.appearance(isEnabled: isEnabled)

        backgroundColor = appearance.backgroundColor
        gradientLayer.isHidden = !appearance.usesGradient
        if appearance.usesGradient {
            ClipyGradient.Foundation.linear.apply(to: gradientLayer)
        }

        setTitleColor(appearance.titleColor, for: .normal)
        setTitleColor(appearance.titleColor, for: .disabled)

        let attributedTitle = ClipyTypography.heading4.attributedString(
            super.title(for: .normal) ?? "",
            color: appearance.titleColor,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        var buttonConfiguration = UIButton.Configuration.plain()
        do {
            buttonConfiguration.attributedTitle = try AttributedString(
                attributedTitle,
                including: \.uiKit
            )
        } catch {
            // Debug에서는 변환 실패를 드러내고, Release에서는 일반 title로 대체해 버튼을 계속 사용할 수 있게 합니다.
            assertionFailure("ClipyFooterActionButton could not convert its title attributes: \(error)")

            buttonConfiguration.title = super.title(for: .normal) ?? ""
        }
        buttonConfiguration.baseForegroundColor = appearance.titleColor
        buttonConfiguration.cornerStyle = .fixed
        buttonConfiguration.background.backgroundColor = appearance.backgroundColor
        // UIKit의 state color 변환을 막아 Style이 정한 background token을 그대로 사용합니다.
        buttonConfiguration.background.backgroundColorTransformer = UIConfigurationColorTransformer { $0 }
        buttonConfiguration.background.cornerRadius = 16
        buttonConfiguration.contentInsets = style.contentInsets
        buttonConfiguration.titleAlignment = .center
        buttonConfiguration.titleLineBreakMode = .byTruncatingTail
        configuration = buttonConfiguration
        invalidateIntrinsicContentSize()
    }

    struct Appearance {
        let backgroundColor: UIColor
        let titleColor: UIColor
        let usesGradient: Bool
    }
}

private extension ClipyFooterActionButton.Style {
    func appearance(isEnabled: Bool) -> ClipyFooterActionButton.Appearance {
        guard isEnabled else {
            return ClipyFooterActionButton.Appearance(
                backgroundColor: ClipyColor.Foundation.neutral50,
                titleColor: ClipyColor.Foundation.neutral800,
                usesGradient: false
            )
        }

        switch self {
        case .gradient:
            return ClipyFooterActionButton.Appearance(
                backgroundColor: .clear,
                titleColor: ClipyColor.Foundation.primary50,
                usesGradient: true
            )
        case .solid:
            return ClipyFooterActionButton.Appearance(
                backgroundColor: ClipyColor.Foundation.primary400,
                titleColor: ClipyColor.Foundation.primary50,
                usesGradient: false
            )
        }
    }

    var contentInsets: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
    }
}
