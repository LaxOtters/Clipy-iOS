//
//  SessionItemCurrencySelector.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import CoreDesignSystem

/// 가격 칸 오른쪽에서 통화를 고르는 pull-down 버튼입니다.
final class SessionItemCurrencySelector: UIButton {
    private var selectedCurrency: SessionItemCurrency

    init(selectedCurrency: SessionItemCurrency) {
        self.selectedCurrency = selectedCurrency
        super.init(frame: .zero)
        showsMenuAsPrimaryAction = true
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func select(_ currency: SessionItemCurrency) {
        selectedCurrency = currency
        render()
        // 입력 칸의 오른쪽 요소는 입력 칸이 배치할 때 크기가 정해지므로, 글자 폭이 바뀌면 다시 배치를 요청합니다.
        superview?.setNeedsLayout()
    }

    private func render() {
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = AttributedString(
            ClipyTypography.body3SemiBold.attributedString(selectedCurrency.rawValue)
        )
        configuration.baseBackgroundColor = ClipyColor.Foundation.primary150
        configuration.baseForegroundColor = ClipyColor.Foundation.neutral800
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.cornerStyle = .capsule
        configuration.buttonSize = .small
        self.configuration = configuration
        menu = UIMenu(children: SessionItemFormValues.currencyOptions.map { currency in
            UIAction(title: currency.rawValue, state: currency == selectedCurrency ? .on : .off) { [weak self] _ in
                self?.select(currency)
            }
        })
        invalidateIntrinsicContentSize()
    }
}
