//
//  SessionBottomSheetRenderingPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

/// Bottom Sheet 상태가 Session surface 안에서 차지해야 하는 화면 수치를 확인합니다.
final class SessionBottomSheetRenderingPolicyTests: XCTestCase {
    func test_expandedState_usesFullAvailableHeight_forDominantComparisonSurface() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760

        XCTAssertEqual(sut.visibleHeight(for: .expanded, availableHeight: availableHeight), availableHeight)
        XCTAssertEqual(sut.offset(for: .expanded, availableHeight: availableHeight), 0)
    }

    func test_minimizedState_keepsLowestVisibleChrome_forCompactUrlLink() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760
        let minimizedHeight = sut.visibleHeight(for: .minimized, availableHeight: availableHeight)

        XCTAssertGreaterThan(minimizedHeight, 0)
        XCTAssertLessThan(minimizedHeight, availableHeight)
        XCTAssertEqual(sut.offset(for: .minimized, availableHeight: availableHeight), availableHeight - minimizedHeight)
    }

    func test_hiddenState_keepsVisibleMiniSheet_forBrowserControlsCue() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760
        let minimizedHeight = sut.visibleHeight(for: .minimized, availableHeight: availableHeight)
        let hiddenHeight = sut.visibleHeight(for: .hidden, availableHeight: availableHeight)

        XCTAssertGreaterThan(hiddenHeight, minimizedHeight)
        XCTAssertLessThan(hiddenHeight, availableHeight)
        XCTAssertEqual(sut.offset(for: .hidden, availableHeight: availableHeight), availableHeight - hiddenHeight)
    }

    func test_peekState_staysBetweenHiddenAndExpanded_forLightweightPreview() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760
        let hiddenHeight = sut.visibleHeight(for: .hidden, availableHeight: availableHeight)
        let peekHeight = sut.visibleHeight(for: .peek, availableHeight: availableHeight)

        XCTAssertGreaterThan(peekHeight, hiddenHeight)
        XCTAssertLessThan(peekHeight, availableHeight)
        XCTAssertEqual(sut.offset(for: .peek, availableHeight: availableHeight), availableHeight - peekHeight)
    }

    func test_clampedOffset_staysInsideExpandedAndMinimizedRange_forInteractiveDrag() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760

        XCTAssertEqual(sut.clampedOffset(-40, availableHeight: availableHeight), 0)
        XCTAssertEqual(
            sut.clampedOffset(1_000, availableHeight: availableHeight),
            sut.offset(for: .minimized, availableHeight: availableHeight)
        )
    }

    func test_contentAlpha_reachesVisibleRange_betweenHiddenAndPeekOffsets() {
        let sut = SessionBottomSheetRenderingPolicy.standard
        let availableHeight: CGFloat = 760
        let hiddenOffset = sut.offset(for: .hidden, availableHeight: availableHeight)
        let peekOffset = sut.offset(for: .peek, availableHeight: availableHeight)

        XCTAssertEqual(sut.contentAlpha(for: .hidden, offset: hiddenOffset, availableHeight: availableHeight), 0)
        XCTAssertEqual(sut.contentAlpha(for: .peek, offset: peekOffset, availableHeight: availableHeight), 1)
    }
}
