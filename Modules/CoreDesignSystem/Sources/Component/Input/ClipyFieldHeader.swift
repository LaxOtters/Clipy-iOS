//
//  ClipyFieldHeader.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

/// 입력 칸 위의 제목줄입니다. 필수 표시와 `현재 / 제한` 글자 수를 함께 그립니다.
/// 글자를 세는 기준은 화면이 정하고, 이 뷰는 넘겨받은 수를 그대로 보여 줍니다.
public final class ClipyFieldHeader: UIView {
    private let titleLabel = UILabel()
    private let characterCountLabel = UILabel()
    private let characterLimit: Int?

    /// characterLimit이 없으면 글자 수를 그리지 않습니다.
    public init(title: String, isRequired: Bool = false, characterLimit: Int? = nil) {
        self.characterLimit = characterLimit
        super.init(frame: .zero)

        let titleText = NSMutableAttributedString(
            attributedString: ClipyTypography.body1SemiBold.attributedString(
                title,
                color: ClipyColor.Foundation.neutral800
            )
        )
        if isRequired {
            titleText.append(
                ClipyTypography.body1SemiBold.attributedString("*", color: ClipyColor.Foundation.red500)
            )
        }
        titleLabel.attributedText = titleText
        characterCountLabel.isHidden = characterLimit == nil
        characterCountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, characterCountLabel])
        stackView.alignment = .center
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        updateCharacterCount(0)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Interface

extension ClipyFieldHeader {
    /// 제한을 넘어도 그대로 표시합니다. 넘었을 때의 오류 모양은 이 수를 받는 쪽의 검증과 함께 정합니다.
    public func updateCharacterCount(_ count: Int) {
        guard let characterLimit else { return }
        characterCountLabel.attributedText = ClipyTypography.body3Bold.attributedString(
            "\(count) / \(characterLimit)",
            color: ClipyColor.Foundation.neutral400,
            alignment: .right
        )
    }
}
