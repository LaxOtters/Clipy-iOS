//
//  ClipyFooterActionButtonContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyFooterActionButtonContractTests: XCTestCase {
    func test_hostLayout_ownsOuterPlacement_whileButtonKeepsSixtyEightPointControlBody() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let button = ClipyFooterActionButton(style: .solid, title: "Save")
        button.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 32),
            button.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -32),
            button.topAnchor.constraint(equalTo: host.topAnchor, constant: 20)
        ])

        host.layoutIfNeeded()

        XCTAssertEqual(button.frame, CGRect(x: 32, y: 20, width: 256, height: 68))
    }

    func test_enabledStyles_haveFixedControlBodySizeAndFigmaShadow() {
        [ClipyFooterActionButton.Style.gradient, .solid].forEach { style in
            let button = ClipyFooterActionButton(style: style, title: "Save")

            XCTAssertEqual(button.intrinsicContentSize.width, UIView.noIntrinsicMetric)
            XCTAssertEqual(button.intrinsicContentSize.height, 68)
            XCTAssertEqual(button.layer.cornerRadius, 16)
            XCTAssertEqual(button.layer.shadowOffset, CGSize(width: 0, height: 4))
            XCTAssertEqual(button.layer.shadowRadius, 10)
            XCTAssertEqual(button.layer.shadowOpacity, 0.1)
            assertColor(button.layer.shadowColor.map(UIColor.init(cgColor:)), equals: .black)
            assertTitleColor(button, equals: Palette.primary50)
        }
    }

    func test_componentConfiguration_rebuildsNormalTitleTypographyInsetsAndStateAppearance() {
        [ClipyFooterActionButton.Style.gradient, .solid].forEach { style in
            let button = ClipyFooterActionButton(style: style, title: "Before")

            assertConfiguration(
                of: button,
                title: "Before",
                titleColor: Palette.primary50,
                backgroundColor: style == .gradient ? .clear : Palette.primary400
            )

            button.setTitle("After", for: .normal)
            button.isEnabled = false

            assertConfiguration(
                of: button,
                title: "After",
                titleColor: Palette.neutral800,
                backgroundColor: Palette.neutral50
            )

            button.isEnabled = true

            assertConfiguration(
                of: button,
                title: "After",
                titleColor: Palette.primary50,
                backgroundColor: style == .gradient ? .clear : Palette.primary400
            )
        }
    }

    func test_componentUpdate_replacesCallerSuppliedConfiguration() {
        let button = ClipyFooterActionButton(style: .solid, title: "Before")
        var callerConfiguration = UIButton.Configuration.filled()
        callerConfiguration.title = "Caller"
        callerConfiguration.contentInsets = .init(top: 1, leading: 2, bottom: 3, trailing: 4)
        button.configuration = callerConfiguration

        button.setTitle("After", for: .normal)

        assertConfiguration(
            of: button,
            title: "After",
            titleColor: Palette.primary50,
            backgroundColor: Palette.primary400
        )
    }

    func test_disablingBothBaseStyles_usesSolidDisabledTreatment_thenRestoresEnabledSurface() {
        [ClipyFooterActionButton.Style.gradient, .solid].forEach { style in
            let button = ClipyFooterActionButton(style: style, title: "Save")

            assertEnabledSurface(of: button, style: style)

            button.isEnabled = false
            assertColor(button.backgroundColor, equals: Palette.neutral50)
            assertTitleColor(button, equals: Palette.neutral800)

            button.isEnabled = true
            assertTitleColor(button, equals: Palette.primary50)
            assertEnabledSurface(of: button, style: style)
        }
    }

    func test_gradientButton_restoresRenderedGradient_afterDisabledRoundTrip_andFollowsResize() {
        let button = ClipyFooterActionButton(style: .gradient, title: "Save")

        let initialImage = render(button, size: CGSize(width: 240, height: 68))
        assertGradientAcrossBody(initialImage)

        button.isEnabled = false
        let disabledImage = render(button, size: CGSize(width: 240, height: 68))
        assertRenderedColor(disabledImage, at: CGPoint(x: 120, y: 34), equals: Palette.neutral50)

        button.isEnabled = true
        let restoredImage = render(button, size: CGSize(width: 320, height: 68))
        assertGradientAcrossBody(restoredImage)
    }

    private func assertGradientAcrossBody(
        _ image: UIImage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let left = renderedColor(in: image, at: CGPoint(x: image.size.width * 0.15, y: image.size.height / 2))
        let right = renderedColor(in: image, at: CGPoint(x: image.size.width * 0.85, y: image.size.height / 2))

        XCTAssertFalse(colorsAreEqual(left, right), file: file, line: line)
        XCTAssertEqual(left.cgColor.alpha, 1, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(right.cgColor.alpha, 1, accuracy: 0.000001, file: file, line: line)
    }

    private func assertConfiguration(
        of button: ClipyFooterActionButton,
        title expectedTitle: String,
        titleColor expectedTitleColor: UIColor,
        backgroundColor expectedBackgroundColor: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let configuration = button.configuration else {
            return XCTFail("Expected a component-owned button configuration.", file: file, line: line)
        }

        XCTAssertEqual(configuration.contentInsets.top, 20, file: file, line: line)
        XCTAssertEqual(configuration.contentInsets.bottom, 20, file: file, line: line)
        XCTAssertEqual(configuration.contentInsets.leading, 0, file: file, line: line)
        XCTAssertEqual(configuration.contentInsets.trailing, 0, file: file, line: line)
        XCTAssertEqual(configuration.cornerStyle, .fixed, file: file, line: line)
        XCTAssertEqual(configuration.background.cornerRadius, 16, file: file, line: line)
        assertColor(configuration.background.backgroundColor, equals: expectedBackgroundColor, file: file, line: line)
        assertTitleColor(button, equals: expectedTitleColor, file: file, line: line)

        guard let configuredTitle = configuration.attributedTitle else {
            return XCTFail("Expected a configured attributed title.", file: file, line: line)
        }
        XCTAssertEqual(String(configuredTitle.characters), expectedTitle, file: file, line: line)

        let attributedTitle = NSAttributedString(configuredTitle)
        let attributes = attributedTitle.attributes(at: 0, effectiveRange: nil)
        let font = attributes[.font] as? UIFont
        let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
        let baselineOffset = (attributes[.baselineOffset] as? NSNumber).map { CGFloat($0.doubleValue) }

        XCTAssertEqual(font?.fontName, ClipyTypography.heading4.font.fontName, file: file, line: line)
        XCTAssertEqual(font?.pointSize, 18, file: file, line: line)
        XCTAssertEqual(paragraphStyle?.minimumLineHeight, 28, file: file, line: line)
        XCTAssertEqual(paragraphStyle?.maximumLineHeight, 28, file: file, line: line)
        XCTAssertEqual(paragraphStyle?.alignment, .center, file: file, line: line)
        XCTAssertEqual(paragraphStyle?.lineBreakMode, .byTruncatingTail, file: file, line: line)
        XCTAssertEqual(
            baselineOffset ?? .nan,
            (ClipyTypography.heading4.lineHeight - ClipyTypography.heading4.font.lineHeight) / 2,
            accuracy: 0.000001,
            file: file,
            line: line
        )
        assertColor(attributes[.foregroundColor] as? UIColor, equals: expectedTitleColor, file: file, line: line)
    }

    private func assertEnabledSurface(
        of button: ClipyFooterActionButton,
        style: ClipyFooterActionButton.Style,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let image = render(button, size: CGSize(width: 240, height: 68))

        switch style {
        case .gradient:
            assertGradientAcrossBody(image, file: file, line: line)
        case .solid:
            assertRenderedColor(
                image,
                at: CGPoint(x: 24, y: 34),
                equals: Palette.primary400,
                file: file,
                line: line
            )
        }
    }
}

private typealias Palette = ClipyColor.Foundation
