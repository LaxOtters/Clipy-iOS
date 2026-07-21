//
//  ClipyTypographyContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyTypographyContractTests: XCTestCase {
    func test_typographyStyles_matchFigmaTextStyles_forFontMetrics() {
        let styles: [(ClipyTextStyle, ExpectedStyle)] = [
            (Typography.heading1, .init("Pretendard-Bold", 28, 38, -0.6)),
            (Typography.heading2, .init("Pretendard-Bold", 24, 34, -0.4)),
            (Typography.heading3, .init("Pretendard-Bold", 20, 30, -0.2)),
            (Typography.heading4, .init("Pretendard-SemiBold", 18, 28, 0)),
            (Typography.body1SemiBold, .init("Pretendard-SemiBold", 16, 24, 0)),
            (Typography.body1Medium, .init("Pretendard-Medium", 16, 24, 0)),
            (Typography.body1Regular, .init("Pretendard-Regular", 16, 24, 0)),
            (Typography.body2SemiBold, .init("Pretendard-SemiBold", 14, 20, 0)),
            (Typography.body2Medium, .init("Pretendard-Medium", 14, 20, 0)),
            (Typography.body2Regular, .init("Pretendard-Regular", 14, 20, 0)),
            (Typography.body3Bold, .init("Pretendard-Bold", 12, 16, 0)),
            (Typography.body3SemiBold, .init("Pretendard-SemiBold", 12, 16, 0)),
            (Typography.body3Medium, .init("Pretendard-Medium", 12, 16, 0)),
            (Typography.body3Regular, .init("Pretendard-Regular", 12, 16, 0)),
            (Typography.tag1Bold, .init("Pretendard-Bold", 10, 15, 0.8)),
            (Typography.tag2Bold, .init("Pretendard-Bold", 8, 10, 0.6))
        ]

        styles.forEach { style, expected in
            XCTAssertEqual(style.font.fontName, expected.postScriptName)
            XCTAssertEqual(style.font.pointSize, expected.size, accuracy: 0.000001)
            XCTAssertEqual(style.lineHeight, expected.lineHeight, accuracy: 0.000001)
            XCTAssertEqual(style.letterSpacing, expected.letterSpacing, accuracy: 0.000001)
        }

        XCTAssertEqual(ClipyTypography.heading4.font.fontName, "Pretendard-SemiBold")
        XCTAssertEqual(ClipyTypography.tag2Bold.font.pointSize, 8)
        XCTAssertEqual(ClipyTypography.tag2Bold.lineHeight, 10)
        XCTAssertEqual(ClipyTypography.tag2Bold.letterSpacing, 0.6)
    }

    func test_attributedString_centersFontMetrics_insideDesignLineHeight() {
        let styles = [
            Typography.heading4,
            Typography.body1Medium,
            Typography.body2Medium
        ]

        styles.forEach { style in
            let attributedText = style.attributedString("Clipy")
            let attributes = attributedText.attributes(at: 0, effectiveRange: nil)
            let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
            let expectedBaselineOffset = (style.lineHeight - style.font.lineHeight) / 2
            let baselineOffset = (attributes[.baselineOffset] as? NSNumber).map { CGFloat($0.doubleValue) }

            XCTAssertEqual(Set(attributes.keys), [.font, .kern, .paragraphStyle, .baselineOffset])
            XCTAssertEqual(attributes[.font] as? UIFont, style.font)
            XCTAssertEqual((attributes[.kern] as? NSNumber)?.doubleValue, style.letterSpacing)
            XCTAssertEqual(paragraphStyle?.minimumLineHeight, style.lineHeight)
            XCTAssertEqual(paragraphStyle?.maximumLineHeight, style.lineHeight)
            XCTAssertEqual(paragraphStyle?.alignment, .natural)
            XCTAssertEqual(paragraphStyle?.lineBreakMode, .byWordWrapping)
            XCTAssertNil(attributes[.foregroundColor])
            XCTAssertEqual(
                baselineOffset ?? .nan,
                expectedBaselineOffset,
                accuracy: 0.000001
            )
        }
    }

    func test_applyingTextStyle_rebuildsExpectedAttributes_andPreservesLabelInputs() {
        let label = UILabel()
        label.text = "Clipy"
        label.textAlignment = .center
        label.textColor = .red
        label.lineBreakMode = .byTruncatingTail

        ClipyTypography.body1Medium.apply(to: label)

        XCTAssertEqual(label.font.fontName, "Pretendard-Medium")
        XCTAssertEqual(label.attributedText?.string, "Clipy")
        XCTAssertEqual(label.textColor, .red)
        XCTAssertEqual(label.textAlignment, .center)
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)

        let attributes = label.attributedText?.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = attributes?[.paragraphStyle] as? NSParagraphStyle
        XCTAssertEqual((attributes?[.kern] as? NSNumber)?.doubleValue, 0)
        XCTAssertEqual(attributes?[.foregroundColor] as? UIColor, .red)
        XCTAssertEqual(paragraphStyle?.minimumLineHeight, 24)
        XCTAssertEqual(paragraphStyle?.maximumLineHeight, 24)
        XCTAssertEqual(paragraphStyle?.alignment, .center)
        XCTAssertEqual(paragraphStyle?.lineBreakMode, .byTruncatingTail)

        let overriddenLabel = UILabel()
        overriddenLabel.attributedText = NSAttributedString(
            string: "Legacy",
            attributes: [
                .foregroundColor: UIColor.blue,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        overriddenLabel.textColor = .red
        overriddenLabel.textAlignment = .right
        overriddenLabel.lineBreakMode = .byClipping

        ClipyTypography.body1Medium.apply(
            to: overriddenLabel,
            text: "Updated",
            color: .green
        )

        let overriddenAttributes = overriddenLabel.attributedText?.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(overriddenLabel.attributedText?.string, "Updated")
        XCTAssertEqual(overriddenLabel.textColor, .green)
        XCTAssertEqual(overriddenLabel.textAlignment, .right)
        XCTAssertEqual(overriddenLabel.lineBreakMode, .byClipping)
        XCTAssertEqual(overriddenAttributes?[.foregroundColor] as? UIColor, .green)
        XCTAssertNil(overriddenAttributes?[.underlineStyle])

        let emptyLabel = UILabel()
        emptyLabel.text = nil
        emptyLabel.attributedText = nil

        ClipyTypography.body1Medium.apply(to: emptyLabel)

        XCTAssertEqual(emptyLabel.font.fontName, "Pretendard-Medium")
        XCTAssertEqual(emptyLabel.attributedText?.string, "")
    }

    func test_applyingTextStyle_withEmptyText_updatesExplicitColor_forLabelState() {
        let label = UILabel()
        label.textColor = .red

        ClipyTypography.body1Medium.apply(
            to: label,
            text: "",
            color: .green
        )

        XCTAssertEqual(label.attributedText?.string, "")
        XCTAssertEqual(label.textColor, .green)
    }
}

private typealias Typography = ClipyTypography

private struct ExpectedStyle {
    let postScriptName: String
    let size: CGFloat
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    init(
        _ postScriptName: String,
        _ size: CGFloat,
        _ lineHeight: CGFloat,
        _ letterSpacing: CGFloat
    ) {
        self.postScriptName = postScriptName
        self.size = size
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }
}
