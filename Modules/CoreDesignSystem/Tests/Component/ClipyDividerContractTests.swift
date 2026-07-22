//
//  ClipyDividerContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyDividerContractTests: XCTestCase {
    func test_spacingVariants_ownExpectedVerticalFootprints_withContainerDrivenWidth() {
        let heights: [(ClipyDivider.Spacing, CGFloat)] = [
            (.large, 40),
            (.medium, 20),
            (.small, 10)
        ]

        heights.forEach { spacing, height in
            let divider = ClipyDivider(spacing: spacing)

            XCTAssertEqual(divider.intrinsicContentSize.width, UIView.noIntrinsicMetric)
            XCTAssertEqual(divider.intrinsicContentSize.height, height)
        }
    }

    func test_spacingVariants_renderCenteredNeutralOneHundredLine_atOnePointFivePoints() {
        [ClipyDivider.Spacing.large, .medium, .small].forEach { spacing in
            let divider = ClipyDivider(spacing: spacing)
            let image = render(divider, size: CGSize(width: 120, height: divider.intrinsicContentSize.height))
            let center = CGPoint(x: image.size.width / 2, y: image.size.height / 2)

            assertRenderedColor(image, at: center, equals: Palette.neutral100)
            XCTAssertEqual(
                renderedVerticalSpan(in: image, atX: center.x),
                1.5,
                accuracy: 0.5
            )
        }
    }
}

private typealias Palette = ClipyColor.Foundation
