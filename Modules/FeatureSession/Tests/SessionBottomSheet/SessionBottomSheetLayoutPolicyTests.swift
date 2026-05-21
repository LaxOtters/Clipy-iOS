//
//  SessionBottomSheetLayoutPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

/// Bottom Sheet 상태가 Session surface 안에서 차지해야 하는 높이를 제품 규칙으로 확인합니다.
final class SessionBottomSheetLayoutPolicyTests: XCTestCase {
    func test_expandedState_usesFullAvailableHeight_forDominantComparisonSurface() {
        let sut = SessionBottomSheetLayoutPolicy.standard
        let availableHeight: CGFloat = 760

        XCTAssertEqual(sut.visibleHeight(for: .expanded, availableHeight: availableHeight), availableHeight)
        XCTAssertEqual(sut.offset(for: .expanded, availableHeight: availableHeight), 0)
    }

    func test_hiddenState_keepsVisibleMiniSheet_forBrowserControlsCue() {
        let sut = SessionBottomSheetLayoutPolicy.standard
        let availableHeight: CGFloat = 760
        let hiddenHeight = sut.visibleHeight(for: .hidden, availableHeight: availableHeight)

        XCTAssertGreaterThan(hiddenHeight, 0)
        XCTAssertLessThan(hiddenHeight, availableHeight)
        XCTAssertEqual(sut.offset(for: .hidden, availableHeight: availableHeight), availableHeight - hiddenHeight)
    }

    func test_peekState_staysBetweenHiddenAndExpanded_forLightweightPreview() {
        let sut = SessionBottomSheetLayoutPolicy.standard
        let availableHeight: CGFloat = 760
        let hiddenHeight = sut.visibleHeight(for: .hidden, availableHeight: availableHeight)
        let peekHeight = sut.visibleHeight(for: .peek, availableHeight: availableHeight)

        XCTAssertGreaterThan(peekHeight, hiddenHeight)
        XCTAssertLessThan(peekHeight, availableHeight)
        XCTAssertEqual(sut.offset(for: .peek, availableHeight: availableHeight), availableHeight - peekHeight)
    }
}
