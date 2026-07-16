//
//  ClipyFontRegistryContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit
import XCTest

@testable import CoreDesignSystem

final class ClipyFontRegistryContractTests: XCTestCase {
    func test_fontRegistry_registersFullPretendardFamily_fromBundledResources() {
        let expectedPostScriptNames = [
            "Pretendard-Thin",
            "Pretendard-ExtraLight",
            "Pretendard-Light",
            "Pretendard-Regular",
            "Pretendard-Medium",
            "Pretendard-SemiBold",
            "Pretendard-Bold",
            "Pretendard-ExtraBold",
            "Pretendard-Black"
        ]

        let registeredNames = expectedPostScriptNames.compactMap { postScriptName in
            let font = ClipyFontRegistry.font(
                postScriptName: postScriptName,
                size: 16,
                fallbackWeight: .regular
            )
            return font.fontName == postScriptName ? font.fontName : nil
        }

        XCTAssertEqual(registeredNames, expectedPostScriptNames)
    }

    func test_fontRegistry_usesMatchingSystemFont_whenRequestedResourceIsMissing() {
        let expected = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let font = ClipyFontRegistry.font(
            postScriptName: "Missing-Pretendard-SemiBold",
            size: 16,
            fallbackWeight: .semibold
        )

        XCTAssertEqual(font.fontName, expected.fontName)
        XCTAssertEqual(font.pointSize, expected.pointSize)
    }
}
