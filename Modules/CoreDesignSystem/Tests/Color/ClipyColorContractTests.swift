//
//  ClipyColorContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/15/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyColorContractTests: XCTestCase {
    func test_foundationColors_matchFigmaHexAndOpacity_forLightModeContract() {
        let colors: [(color: UIColor, expected: (hex: UInt32, alpha: CGFloat))] = [
            (Palette.primary50, (0xFFFFFF, 1)),
            (Palette.primary100, (0xF9F9FE, 1)),
            (Palette.primary150, (0xF4F2FD, 1)),
            (Palette.primary200, (0xCFCCF8, 1)),
            (Palette.primary300, (0xA49FF2, 1)),
            (Palette.primary400, (0x7A73EB, 1)),
            (Palette.primary500, (0x4F46E5, 1)),
            (Palette.primary600, (0x291FD9, 1)),
            (Palette.primary700, (0x2118AD, 1)),
            (Palette.primary800, (0x181280, 1)),
            (Palette.primary900, (0x100C53, 1)),
            (Palette.accent50, (0xFFFFFF, 1)),
            (Palette.accent100, (0xD6F7F3, 1)),
            (Palette.accent200, (0xACEEE6, 1)),
            (Palette.accent300, (0x82E5D9, 1)),
            (Palette.accent400, (0x57DDCC, 1)),
            (Palette.accent500, (0x2DD4BF, 1)),
            (Palette.accent600, (0x23AB9A, 1)),
            (Palette.accent700, (0x1A8174, 1)),
            (Palette.accent800, (0x12564E, 1)),
            (Palette.accent900, (0x092C28, 1)),
            (Palette.neutral50, (0xFAFAFA, 1)),
            (Palette.neutral100, (0xF4F4F5, 1)),
            (Palette.neutral200, (0xE4E4E7, 1)),
            (Palette.neutral300, (0xD4D4D8, 1)),
            (Palette.neutral400, (0xA1A1AA, 1)),
            (Palette.neutral500, (0x71717A, 1)),
            (Palette.neutral600, (0x52525B, 1)),
            (Palette.neutral700, (0x3F3F46, 1)),
            (Palette.neutral800, (0x27272A, 1)),
            (Palette.neutral900, (0x18181B, 1)),
            (Palette.neutral950, (0x09090B, 1)),
            (Palette.error100, (0xFFDAD6, 1)),
            (Palette.error700, (0xBA1A1A, 1)),
            (Palette.alphaWhite20, (0xFFFFFF, 0.2)),
            (Palette.alphaWhite70, (0xFFFFFF, 0.7)),
            (Palette.alphaWhite0Point2, (0xFFFFFF, 0.002)),
            (Palette.alphaWhite10, (0xFFFFFF, 0.1)),
            (Palette.alphaBlack20, (0x000000, 0.2)),
            (Palette.alphaBlack60, (0x000000, 0.6)),
            (Palette.alphaBlack15, (0x000000, 0.15)),
            (Palette.overlayBackground, (0x000000, 0.2))
        ]

        colors.forEach { entry in
            assertColor(entry.color, hex: entry.expected.hex, alpha: entry.expected.alpha)
        }
    }

    func test_primary50AndAccent50_keepSeparateAPIs_despiteMatchingWhiteValuesInFigma() {
        XCTAssertEqual(Palette.primary50, Palette.accent50)
    }

    func test_alphaExceptions_keepLowWhiteAndPureBlackValues_fromDesignerConfirmation() {
        assertColor(Palette.alphaWhite0Point2, hex: 0xFFFFFF, alpha: 0.002)
        assertColor(Palette.alphaBlack20, hex: 0x000000, alpha: 0.2)
        assertColor(Palette.overlayBackground, hex: 0x000000, alpha: 0.2)
    }

    private func assertColor(
        _ color: UIColor,
        hex: UInt32,
        alpha expectedAlpha: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        XCTAssertTrue(
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
            file: file,
            line: line
        )
        XCTAssertEqual(red, CGFloat((hex >> 16) & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(green, CGFloat((hex >> 8) & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(blue, CGFloat(hex & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(alpha, expectedAlpha, accuracy: 0.000001, file: file, line: line)
    }
}

private typealias Palette = ClipyColor.Foundation
