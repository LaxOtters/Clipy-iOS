//
//  SessionBottomSheetPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 6/3/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

final class SessionBottomSheetPolicyTests: XCTestCase {
    func test_bottomSheetStates_useChromeDetents_forSessionBrowsingPolicy() {
        let sut = SessionBottomSheetPolicy.standard
        let availableHeight: CGFloat = 760

        XCTAssertEqual(sut.visibleHeight(for: .hidden, availableHeight: availableHeight), 0)
        XCTAssertEqual(sut.visibleHeight(for: .minimized, availableHeight: availableHeight), 120)
        XCTAssertEqual(sut.visibleHeight(for: .peek, availableHeight: availableHeight), 286)
        XCTAssertEqual(sut.visibleHeight(for: .expanded, availableHeight: availableHeight), availableHeight)
    }

    func test_dragFromHidden_keepsHidden_becauseHiddenHasNoGrabberStart() {
        let sut = SessionBottomSheetPolicy.standard

        let state = sut.nextState(
            from: .hidden,
            action: dragEnded(endVisibleHeight: 286, translationY: -286)
        )

        XCTAssertEqual(state, .hidden)
    }

    func test_slowDragInsideRetention_keepsCurrentState_forSmallGrabberMovement() {
        let sut = SessionBottomSheetPolicy.standard

        let expandedState = sut.nextState(
            from: .expanded,
            action: dragEnded(endVisibleHeight: 745, translationY: 15)
        )
        let peekState = sut.nextState(
            from: .peek,
            action: dragEnded(endVisibleHeight: 300, translationY: -14)
        )
        let minimizedState = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 105, translationY: 15)
        )

        XCTAssertEqual(expandedState, .expanded)
        XCTAssertEqual(peekState, .peek)
        XCTAssertEqual(minimizedState, .minimized)
    }

    func test_slowDragBeyondRetention_movesToNextState_forIntentionalDirection() {
        let sut = SessionBottomSheetPolicy.standard

        let expandedCollapse = sut.nextState(
            from: .expanded,
            action: dragEnded(endVisibleHeight: 700, translationY: 60)
        )
        let peekCollapse = sut.nextState(
            from: .peek,
            action: dragEnded(endVisibleHeight: 240, translationY: 46)
        )
        let minimizedCollapse = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 80, translationY: 40)
        )
        let minimizedExpansion = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 170, translationY: -50)
        )

        XCTAssertEqual(expandedCollapse, .peek)
        XCTAssertEqual(peekCollapse, .minimized)
        XCTAssertEqual(minimizedCollapse, .hidden)
        XCTAssertEqual(minimizedExpansion, .peek)
    }

    func test_slowLongDragAcrossSnapZones_canJumpMultipleStates_forDirectSheetManipulation() {
        let sut = SessionBottomSheetPolicy.standard

        let longCollapse = sut.nextState(
            from: .expanded,
            action: dragEnded(endVisibleHeight: 130, translationY: 630)
        )
        let longExpansion = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 750, translationY: -630)
        )

        XCTAssertEqual(longCollapse, .minimized)
        XCTAssertEqual(longExpansion, .expanded)
    }

    func test_fastDrag_usesVelocityIntent_forQuickExpansionAndCollapse() {
        let sut = SessionBottomSheetPolicy.standard

        let fastExpansionFromMinimized = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 120, translationY: -20, velocityY: -3_200)
        )
        let fastExpansionFromPeek = sut.nextState(
            from: .peek,
            action: dragEnded(endVisibleHeight: 286, translationY: -20, velocityY: -3_200)
        )
        let fastCollapseFromExpanded = sut.nextState(
            from: .expanded,
            action: dragEnded(endVisibleHeight: 760, translationY: 20, velocityY: 3_200)
        )
        let fastCollapseFromPeek = sut.nextState(
            from: .peek,
            action: dragEnded(endVisibleHeight: 286, translationY: 20, velocityY: 3_200)
        )
        let fastWebFocusFromMinimized = sut.nextState(
            from: .minimized,
            action: dragEnded(endVisibleHeight: 120, translationY: 20, velocityY: 3_200)
        )

        XCTAssertEqual(fastExpansionFromMinimized, .expanded)
        XCTAssertEqual(fastExpansionFromPeek, .expanded)
        XCTAssertEqual(fastCollapseFromExpanded, .minimized)
        XCTAssertEqual(fastCollapseFromPeek, .minimized)
        XCTAssertEqual(fastWebFocusFromMinimized, .hidden)
    }

    func test_dragProgressBetweenPeekAndExpanded_crossFadesSheetContent_forComparisonEntry() {
        let sut = SessionBottomSheetPolicy.standard
        let availableHeight: CGFloat = 760

        let minimizedContent = sut.contentAlpha(
            offset: availableHeight - 120,
            availableHeight: availableHeight
        )
        let peekContent = sut.contentAlpha(
            offset: availableHeight - 286,
            availableHeight: availableHeight
        )
        let middleContent = sut.contentAlpha(
            offset: availableHeight - 523,
            availableHeight: availableHeight
        )
        let expandedContent = sut.contentAlpha(
            offset: 0,
            availableHeight: availableHeight
        )

        XCTAssertEqual(minimizedContent, .init(peek: 0, expanded: 0))
        XCTAssertEqual(peekContent, .init(peek: 1, expanded: 0))
        XCTAssertEqual(middleContent.peek, 0.5, accuracy: 0.001)
        XCTAssertEqual(middleContent.expanded, 0.5, accuracy: 0.001)
        XCTAssertEqual(expandedContent, .init(peek: 0, expanded: 1))
    }

    func test_browserControlRowVisibility_showsOnlyWhileBrowsingChromeCanStayVisible() {
        let sut = SessionBottomSheetPolicy.standard

        XCTAssertFalse(sut.isBrowserControlRowVisible(for: .hidden))
        XCTAssertTrue(sut.isBrowserControlRowVisible(for: .minimized))
        XCTAssertTrue(sut.isBrowserControlRowVisible(for: .peek))
        XCTAssertFalse(sut.isBrowserControlRowVisible(for: .expanded))
    }

    private func dragEnded(
        endVisibleHeight: CGFloat,
        translationY: CGFloat,
        velocityY: CGFloat = 0,
        availableHeight: CGFloat = 760
    ) -> SessionBottomSheetAction {
        .dragEnded(
            SessionBottomSheetDragEndContext(
                translationY: translationY,
                velocityY: velocityY,
                endOffset: availableHeight - endVisibleHeight,
                availableHeight: availableHeight
            )
        )
    }
}
