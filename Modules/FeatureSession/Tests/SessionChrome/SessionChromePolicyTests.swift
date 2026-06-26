//
//  SessionChromePolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 6/26/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

final class SessionChromePolicyTests: XCTestCase {
    func test_topBarToggleBetweenBrowsingStates_switchesHiddenAndMinimized_forFocusedBrowsing() {
        let sut = SessionChromePolicy()

        XCTAssertEqual(
            sut.nextState(from: .browsingMinimized, action: .topBarToggle),
            .browsingHidden
        )
        XCTAssertEqual(
            sut.nextState(from: .browsingHidden, action: .topBarToggle),
            .browsingMinimized
        )
    }

    func test_topBarToggleInPeek_changesTopBarOnly_keepsBottomSheetPeek() {
        let sut = SessionChromePolicy()

        let folded = sut.nextState(
            from: .comparingPeek(topBarState: .unfolded),
            action: .topBarToggle
        )
        let unfolded = sut.nextState(
            from: .comparingPeek(topBarState: .folded),
            action: .topBarToggle
        )

        XCTAssertEqual(folded, .comparingPeek(topBarState: .folded))
        XCTAssertEqual(unfolded, .comparingPeek(topBarState: .unfolded))
    }

    func test_rootScrollDownFromMinimized_hidesChrome_whenRootScrollIsEligible() {
        let sut = SessionChromePolicy()

        let state = sut.nextState(
            from: .browsingMinimized,
            action: .webRootScroll(.init(direction: .down, isEligibleForChromeTransition: true))
        )

        XCTAssertEqual(state, .browsingHidden)
    }

    func test_rootScrollUpFromHidden_restoresMinimized_whenRootScrollIsEligible() {
        let sut = SessionChromePolicy()

        let state = sut.nextState(
            from: .browsingHidden,
            action: .webRootScroll(.init(direction: .up, isEligibleForChromeTransition: true))
        )

        XCTAssertEqual(state, .browsingMinimized)
    }

    func test_rootScrollDoesNotChangeChrome_whenEventIsNotEligible() {
        let sut = SessionChromePolicy()

        let state = sut.nextState(
            from: .browsingMinimized,
            action: .webRootScroll(.init(direction: .down, isEligibleForChromeTransition: false))
        )

        XCTAssertEqual(state, .browsingMinimized)
    }

    func test_rootScrollInPeekAndExpanded_doesNotChangeChrome_becauseComparisonStatesIgnoreRootScroll() {
        let sut = SessionChromePolicy()
        let scrollDown = SessionChromeAction.webRootScroll(
            .init(direction: .down, isEligibleForChromeTransition: true)
        )
        let scrollUp = SessionChromeAction.webRootScroll(
            .init(direction: .up, isEligibleForChromeTransition: true)
        )

        XCTAssertEqual(
            sut.nextState(from: .comparingPeek(topBarState: .unfolded), action: scrollDown),
            .comparingPeek(topBarState: .unfolded)
        )
        XCTAssertEqual(
            sut.nextState(from: .comparingExpanded(topBarState: .folded), action: scrollUp),
            .comparingExpanded(topBarState: .folded)
        )
    }

    func test_bottomSheetDrag_usesBottomSheetPolicy_thenMapsToChromeState() {
        let sut = SessionChromePolicy()

        let minimized = sut.nextState(
            from: .comparingPeek(topBarState: .unfolded),
            action: .bottomSheetDragEnded(dragEnded(endVisibleHeight: 240, translationY: 46))
        )
        let peek = sut.nextState(
            from: .browsingMinimized,
            action: .bottomSheetDragEnded(dragEnded(endVisibleHeight: 170, translationY: -50))
        )

        XCTAssertEqual(minimized, .browsingMinimized)
        XCTAssertEqual(peek, .comparingPeek(topBarState: .unfolded))
    }

    func test_navigationAfterInitialLoad_restoresBrowsingMinimized_forDefaultViewport() {
        let sut = SessionChromePolicy()

        let state = sut.nextState(
            from: .comparingPeek(topBarState: .unfolded),
            action: .navigationFinishedAfterInitialLoad
        )

        XCTAssertEqual(state, .browsingMinimized)
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
