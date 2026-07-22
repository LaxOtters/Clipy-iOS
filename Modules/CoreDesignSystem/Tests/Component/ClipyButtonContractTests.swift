//
//  ClipyButtonContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyButtonContractTests: XCTestCase {
    func test_publicVariants_roundTripExactFigmaAppearances_forEnabledStateChanges() {
        ButtonReference.all.forEach { reference in
            let button = ClipyButton(variant: reference.variant, title: "Continue")

            XCTAssertEqual(button.intrinsicContentSize.width, UIView.noIntrinsicMetric)
            XCTAssertEqual(button.intrinsicContentSize.height, reference.height)
            XCTAssertEqual(button.layer.cornerRadius, reference.cornerRadius)
            assertContentInsets(button)
            assertCorner(button, equals: reference.cornerRadius)
            assertAppearance(button, equals: reference.enabled)
            assertTypography(button, equals: reference.typography)

            button.isEnabled = false

            assertAppearance(button, equals: reference.disabled)
            assertTypography(button, equals: reference.typography)

            button.isEnabled = true

            assertAppearance(button, equals: reference.enabled)
            assertTypography(button, equals: reference.typography)
        }
    }

    func test_updatingNormalTitle_survivesDisabledRoundTrip_withVariantTypography() {
        ButtonReference.all.forEach { reference in
            let button = ClipyButton(variant: reference.variant, title: "Before")

            button.setTitle("After", for: .normal)
            button.isEnabled = false

            assertConfiguredTitle(button, equals: "After")
            assertTypography(button, equals: reference.typography)
            assertAppearance(button, equals: reference.disabled)

            button.isEnabled = true

            assertConfiguredTitle(button, equals: "After")
            assertTypography(button, equals: reference.typography)
            assertAppearance(button, equals: reference.enabled)
        }
    }
}

private typealias Palette = ClipyColor.Foundation

private struct ButtonReference {
    let variant: ClipyButton.Variant
    let enabled: ExpectedAppearance
    let disabled: ExpectedAppearance
    let height: CGFloat
    let cornerRadius: CGFloat
    let typography: ClipyTextStyle

    static let all = [
        ButtonReference(
            variant: .primaryMedium,
            enabled: ExpectedAppearance(background: Palette.primary400, title: Palette.primary50),
            disabled: ExpectedAppearance(background: Palette.primary300, title: Palette.primary100),
            height: 50,
            cornerRadius: 12,
            typography: ClipyTypography.body1Medium
        ),
        ButtonReference(
            variant: .secondaryMedium,
            enabled: ExpectedAppearance(
                background: Palette.neutral100,
                title: Palette.neutral800,
                borderWidth: 1,
                border: Palette.neutral200
            ),
            disabled: ExpectedAppearance(
                background: Palette.neutral50,
                title: Palette.neutral300,
                borderWidth: 1,
                border: Palette.neutral200
            ),
            height: 50,
            cornerRadius: 12,
            typography: ClipyTypography.body1Medium
        ),
        ButtonReference(
            variant: .primarySmall,
            enabled: ExpectedAppearance(background: Palette.primary400, title: Palette.primary50),
            disabled: ExpectedAppearance(background: Palette.neutral100, title: Palette.neutral800),
            height: 36,
            cornerRadius: 18,
            typography: ClipyTypography.body2Medium
        )
    ]
}

private struct ExpectedAppearance {
    let background: UIColor
    let title: UIColor
    let borderWidth: CGFloat
    let border: UIColor?

    init(
        background: UIColor,
        title: UIColor,
        borderWidth: CGFloat = 0,
        border: UIColor? = nil
    ) {
        self.background = background
        self.title = title
        self.borderWidth = borderWidth
        self.border = border
    }
}

private func assertAppearance(
    _ button: ClipyButton,
    equals expected: ExpectedAppearance,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    assertColor(
        button.configuration?.background.backgroundColor,
        equals: expected.background,
        file: file,
        line: line
    )
    assertTitleColor(button, equals: expected.title, file: file, line: line)

    guard let attributedTitle = button.configuration?.attributedTitle else {
        return XCTFail("Expected a configured attributed title.", file: file, line: line)
    }
    let attributedTitleValue = NSAttributedString(attributedTitle)
    guard let attributedTitleColor = attributedTitleValue.attribute(
        .foregroundColor,
        at: 0,
        effectiveRange: nil
    ) as? UIColor else {
        return XCTFail("Expected attributed title foreground color.", file: file, line: line)
    }
    assertColor(attributedTitleColor, equals: expected.title, file: file, line: line)

    XCTAssertEqual(button.layer.borderWidth, expected.borderWidth, file: file, line: line)

    if let border = expected.border {
        XCTAssertNotNil(button.layer.borderColor, file: file, line: line)
        if let borderColor = button.layer.borderColor {
            assertColor(UIColor(cgColor: borderColor), equals: border, file: file, line: line)
        }
    } else {
        XCTAssertNil(button.layer.borderColor, file: file, line: line)
    }
}

private func assertTypography(
    _ button: ClipyButton,
    equals expected: ClipyTextStyle,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let attributedTitle = button.configuration?.attributedTitle else {
        return XCTFail("Expected a configured attributed title.", file: file, line: line)
    }
    let title = NSAttributedString(attributedTitle)
    let font = title.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
    let paragraphStyle = title.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle

    XCTAssertEqual(font?.fontName, expected.font.fontName, file: file, line: line)
    XCTAssertEqual(font?.pointSize, expected.font.pointSize, file: file, line: line)
    XCTAssertEqual(paragraphStyle?.minimumLineHeight, expected.lineHeight, file: file, line: line)
    XCTAssertEqual(paragraphStyle?.maximumLineHeight, expected.lineHeight, file: file, line: line)
}

private func assertConfiguredTitle(
    _ button: ClipyButton,
    equals expected: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(
        button.configuration?.attributedTitle.map { String($0.characters) },
        expected,
        file: file,
        line: line
    )
}

private func assertContentInsets(
    _ button: ClipyButton,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let insets = button.configuration?.contentInsets
    XCTAssertEqual(insets?.top, 0, file: file, line: line)
    XCTAssertEqual(insets?.bottom, 0, file: file, line: line)
    XCTAssertEqual(insets?.leading, 20, file: file, line: line)
    XCTAssertEqual(insets?.trailing, 20, file: file, line: line)
}

private func assertCorner(
    _ button: ClipyButton,
    equals expected: CGFloat,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(button.configuration?.cornerStyle, .fixed, file: file, line: line)
    XCTAssertEqual(button.configuration?.background.cornerRadius, expected, file: file, line: line)
}
