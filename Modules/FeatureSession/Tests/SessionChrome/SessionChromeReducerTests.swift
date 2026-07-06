//
//  SessionChromeReducerTests.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import XCTest

@testable import FeatureSession

final class SessionChromeReducerTests: XCTestCase {
    typealias Fixture = SessionChromeReducerTestFixture

    func test_topBarToggleBetweenBrowsingStates_switchesHiddenAndMinimized_forFocusedBrowsing() {
        let sut = SessionChromeReducer()

        let hidden = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .topBarToggle
        )
        let minimized = sut.reduce(
            Fixture.state(showing: .browsingHidden),
            action: .topBarToggle
        )

        XCTAssertEqual(hidden.presentation, .browsingHidden)
        XCTAssertEqual(minimized.presentation, .browsingMinimized)
    }

    func test_topBarToggleInPeek_changesTopBarOnly_keepsBottomSheetPeek() {
        let sut = SessionChromeReducer()

        let folded = sut.reduce(
            Fixture.state(showing: .comparingPeek(topBarState: .unfolded)),
            action: .topBarToggle
        )
        let unfolded = sut.reduce(
            Fixture.state(showing: .comparingPeek(topBarState: .folded)),
            action: .topBarToggle
        )

        XCTAssertEqual(folded.presentation, .comparingPeek(topBarState: .folded))
        XCTAssertEqual(unfolded.presentation, .comparingPeek(topBarState: .unfolded))
    }

    func test_topBarToggleInExpanded_changesTopBarOnly_keepsBottomSheetExpanded() {
        let sut = SessionChromeReducer()

        let folded = sut.reduce(
            Fixture.state(showing: .comparingExpanded(topBarState: .unfolded)),
            action: .topBarToggle
        )
        let unfolded = sut.reduce(
            Fixture.state(showing: .comparingExpanded(topBarState: .folded)),
            action: .topBarToggle
        )

        XCTAssertEqual(folded.presentation, .comparingExpanded(topBarState: .folded))
        XCTAssertEqual(unfolded.presentation, .comparingExpanded(topBarState: .unfolded))
    }

    func test_topBarToggleDuringWebRootDragging_isIgnored_forInteractionOwnership() {
        let sut = SessionChromeReducer()
        let state = Fixture.draggingState(showing: .browsingMinimized)

        let nextState = sut.reduce(state, action: .topBarToggle)

        XCTAssertEqual(nextState, state)
    }

    func test_bottomSheetDrag_routesThroughChromeReducer_forSharedChromeState() {
        let sut = SessionChromeReducer()
        let state = sut.reduce(
            Fixture.state(showing: .comparingPeek(topBarState: .unfolded)),
            action: .bottomSheetDragEnded(
                Fixture.bottomSheetDragEnded(endVisibleHeight: 240, translationY: 46)
            )
        )

        XCTAssertEqual(state.presentation, .browsingMinimized)
    }

    func test_bottomSheetDragDuringWebRootDragging_appliesSheetResultAndClearsInteraction() {
        let sut = SessionChromeReducer()
        let state = sut.reduce(
            Fixture.draggingState(showing: .browsingMinimized),
            action: .bottomSheetDragEnded(
                Fixture.bottomSheetDragEnded(endVisibleHeight: 170, translationY: -50)
            )
        )

        XCTAssertEqual(state.presentation, .comparingPeek(topBarState: .unfolded))
        XCTAssertEqual(state.interaction, .idle)
    }

    func test_navigationAfterInitialLoad_restoresBrowsingMinimized_forDefaultViewport() {
        let sut = SessionChromeReducer()
        let state = sut.reduce(
            .newSession,
            action: .navigationFinishedAfterInitialLoad
        )

        XCTAssertEqual(state.presentation, .browsingMinimized)
    }

    func test_navigationAfterInitialLoad_keepsNewSessionChrome_duringActiveWebRootDrag() {
        let sut = SessionChromeReducer()
        let dragging = Fixture.draggingState(showing: .newSession)

        let state = sut.reduce(
            dragging,
            action: .navigationFinishedAfterInitialLoad
        )

        XCTAssertEqual(state, dragging)
    }

    func test_navigationAfterInitialLoad_keepsChangedChrome_forUserInteractionDuringLoading() {
        let sut = SessionChromeReducer()
        let changedStates: [SessionChromeState] = [
            .browsingHidden,
            .browsingMinimized,
            .comparingPeek(topBarState: .folded),
            .comparingExpanded(topBarState: .unfolded)
        ]

        changedStates.forEach { presentation in
            let state = sut.reduce(
                Fixture.state(showing: presentation),
                action: .navigationFinishedAfterInitialLoad
            )

            XCTAssertEqual(state.presentation, presentation)
        }
    }
}
