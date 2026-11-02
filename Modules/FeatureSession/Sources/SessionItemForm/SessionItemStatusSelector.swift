//
//  SessionItemStatusSelector.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import CoreDesignSystem
import CoreDomain

/// 상품 상태 세 가지 중 하나를 고르는 칩 묶음입니다.
final class SessionItemStatusSelector: UIStackView {
    private var selectedStatus: ItemIntentState
    private var buttons: [ItemIntentState: UIButton] = [:]

    init(selectedStatus: ItemIntentState) {
        self.selectedStatus = selectedStatus
        super.init(frame: .zero)
        spacing = 8

        SessionItemFormValues.statusOptions.forEach { status in
            let button = UIButton(type: .system)
            button.addAction(UIAction { [weak self] _ in self?.select(status) }, for: .touchUpInside)
            // 남는 폭은 뒤의 빈 view가 가져가고, 칩 글자는 줄바꿈되지 않게 합니다.
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.setContentHuggingPriority(.required, for: .horizontal)
            buttons[status] = button
            addArrangedSubview(button)
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addArrangedSubview(spacer)
        render()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func select(_ status: ItemIntentState) {
        selectedStatus = status
        render()
    }

    private func render() {
        buttons.forEach { status, button in
            let isSelected = status == selectedStatus
            var configuration = UIButton.Configuration.filled()
            configuration.attributedTitle = AttributedString(
                ClipyTypography.body3SemiBold.attributedString(status.rawValue)
            )
            configuration.image = UIImage(systemName: status.iconName)
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13)
            configuration.imagePadding = 6
            configuration.titleLineBreakMode = .byClipping
            configuration.cornerStyle = .capsule
            configuration.buttonSize = .small
            configuration.baseBackgroundColor = isSelected
                ? ClipyColor.Foundation.primary500
                : ClipyColor.Foundation.primary150
            configuration.baseForegroundColor = isSelected
                ? ClipyColor.Foundation.neutral50
                : ClipyColor.Foundation.neutral700
            button.configuration = configuration
        }
    }
}

private extension ItemIntentState {
    var iconName: String {
        switch self {
        case .interested:
            return "checkmark.circle.fill"
        case .hold:
            return "pause.circle"
        case .dropped:
            return "xmark.circle"
        }
    }
}
