//
//  ClipyButton.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit

/// 화면의 action을 정해진 스타일과 크기로 표현하는 공용 버튼입니다.
/// 가로 길이와 배치는 이 버튼을 사용하는 화면이 정합니다.
public final class ClipyButton: UIButton {
    /// 디자인에서 허용한 버튼 모양입니다.
    /// 비활성 스타일은 variant를 늘리지 않고 `isEnabled`로 바꿉니다.
    public enum Variant {
        case primaryMedium
        case secondaryMedium
        case primarySmall
    }

    public override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: variant.height)
    }

    /// 공개 variant를 늘리지 않고 특정 화면의 primary 색만 바꿀 때 씁니다.
    enum ColorRole {
        case standard
        case primary500
    }

    private let variant: Variant
    private let colorRole: ColorRole

    public convenience init(variant: Variant, title: String) {
        self.init(variant: variant, title: title, colorRole: .standard)
    }

    init(variant: Variant, title: String, colorRole: ColorRole) {
        self.variant = variant
        self.colorRole = colorRole
        super.init(frame: .zero)

        configuration = .plain()
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentHorizontalAlignment = .center
        super.setTitle(title, for: .normal)
        updateAppearance()
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

private extension ClipyButton {
    func updateAppearance() {
        let appearance = variant.appearance(isEnabled: isEnabled, colorRole: colorRole)

        backgroundColor = appearance.backgroundColor
        layer.cornerRadius = variant.cornerRadius
        layer.borderWidth = appearance.borderWidth
        layer.borderColor = appearance.borderColor?.cgColor
        setTitleColor(appearance.titleColor, for: .normal)
        setTitleColor(appearance.titleColor, for: .disabled)

        let textStyle = variant.textStyle
        let attributedTitle = textStyle.attributedString(
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
            // 속성 변환이 깨지면 Debug에서는 바로 보이게 하고, Release에서는 title만 남깁니다.
            assertionFailure("ClipyButton could not convert its title attributes: \(error)")

            buttonConfiguration.title = super.title(for: .normal) ?? ""
        }
        buttonConfiguration.baseForegroundColor = appearance.titleColor
        buttonConfiguration.cornerStyle = .fixed
        buttonConfiguration.background.backgroundColor = appearance.backgroundColor
        // UIKit이 state별 색을 다시 계산하지 않게 해서 variant가 고른 background token을 그대로 씁니다.
        buttonConfiguration.background.backgroundColorTransformer = UIConfigurationColorTransformer { $0 }
        buttonConfiguration.background.cornerRadius = variant.cornerRadius
        buttonConfiguration.contentInsets = variant.contentInsets
        buttonConfiguration.titleAlignment = .center
        buttonConfiguration.titleLineBreakMode = .byTruncatingTail
        configuration = buttonConfiguration
        invalidateIntrinsicContentSize()
    }

    struct Appearance {
        let backgroundColor: UIColor
        let titleColor: UIColor
        let borderWidth: CGFloat
        let borderColor: UIColor?

        init(
            backgroundColor: UIColor,
            titleColor: UIColor,
            borderWidth: CGFloat = 0,
            borderColor: UIColor? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.titleColor = titleColor
            self.borderWidth = borderWidth
            self.borderColor = borderColor
        }
    }
}

private extension ClipyButton.Variant {
    func appearance(
        isEnabled: Bool,
        colorRole: ClipyButton.ColorRole
    ) -> ClipyButton.Appearance {
        switch (self, isEnabled, colorRole) {
        case (.primaryMedium, true, .primary500):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.primary500,
                titleColor: ClipyColor.Foundation.primary50
            )
        case (.primaryMedium, true, .standard), (.primarySmall, true, _):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.primary400,
                titleColor: ClipyColor.Foundation.primary50
            )
        case (.primaryMedium, false, _):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.primary300,
                titleColor: ClipyColor.Foundation.primary100
            )
        case (.secondaryMedium, true, _):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.neutral100,
                titleColor: ClipyColor.Foundation.neutral800,
                borderWidth: 1,
                borderColor: ClipyColor.Foundation.neutral200
            )
        case (.secondaryMedium, false, _):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.neutral50,
                titleColor: ClipyColor.Foundation.neutral300,
                borderWidth: 1,
                borderColor: ClipyColor.Foundation.neutral200
            )
        case (.primarySmall, false, _):
            ClipyButton.Appearance(
                backgroundColor: ClipyColor.Foundation.neutral100,
                titleColor: ClipyColor.Foundation.neutral800
            )
        }
    }

    var height: CGFloat {
        switch self {
        case .primaryMedium, .secondaryMedium:
            50
        case .primarySmall:
            36
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .primaryMedium, .secondaryMedium:
            12
        case .primarySmall:
            18
        }
    }

    var contentInsets: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
    }

    var textStyle: ClipyTextStyle {
        switch self {
        case .primaryMedium, .secondaryMedium:
            ClipyTypography.body1Medium
        case .primarySmall:
            ClipyTypography.body2Medium
        }
    }
}
