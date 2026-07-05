//
//  SessionChromeReducerWebRootScrollTests.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import XCTest

@testable import FeatureSession

final class SessionChromeReducerWebRootScrollTests: XCTestCase {
    typealias Fixture = SessionChromeReducerTestFixture

    func test_externalScroll_doesNotChangeChrome_withoutActiveDragSession() {
        let sut = SessionChromeReducer()
        let state = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.externalScroll(Fixture.snapshot(offsetY: 40)))
        )

        XCTAssertEqual(state.presentation, .browsingMinimized)
        XCTAssertEqual(state.interaction, .idle)
    }

    func test_draggedRootScroll_hidesChrome_onlyInsideActiveDragSession() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let hidden = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 14)))
        )
        let ignoredWithoutDrag = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 14)))
        )

        XCTAssertEqual(hidden.presentation, .browsingHidden)
        XCTAssertEqual(ignoredWithoutDrag.presentation, .browsingMinimized)
    }

    func test_draggedRootScrollUp_restoresMinimizedChrome_fromHiddenBrowsing() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingHidden),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 40)))
        )
        let minimized = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 24)))
        )

        XCTAssertEqual(minimized.presentation, .browsingMinimized)
    }

    func test_slowRootScroll_accumulatesMovementInsideActiveDragSession() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let belowThreshold = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 6)))
        )
        let hidden = sut.reduce(
            belowThreshold,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 13)))
        )

        XCTAssertEqual(belowThreshold.presentation, .browsingMinimized)
        XCTAssertEqual(hidden.presentation, .browsingHidden)
    }

    func test_shortRootPageMovement_keepsChrome_forIneligibleScrollSurface() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0, contentHeight: 900)))
        )
        let unchanged = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 30, contentHeight: 900)))
        )

        XCTAssertEqual(unchanged.presentation, .browsingMinimized)
    }

    func test_topRubberBandRebound_doesNotChangeChrome_forEdgeBounceNoise() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingHidden),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 4)))
        )
        let rubberBand = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: -18)))
        )
        let rebound = sut.reduce(
            rubberBand,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 0)))
        )

        XCTAssertEqual(rebound.presentation, .browsingHidden)
    }

    func test_bottomRubberBandRebound_doesNotChangeChrome_forEdgeBounceNoise() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 380)))
        )
        let rubberBand = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 430)))
        )
        let rebound = sut.reduce(
            rubberBand,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 400)))
        )

        XCTAssertEqual(rebound.presentation, .browsingMinimized)
    }

    func test_dragBeginningOutOfBounds_reanchorsAfterRebound_beforeChangingChrome() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: -20)))
        )
        let rebound = sut.reduce(
            dragging,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 0)))
        )
        let hidden = sut.reduce(
            rebound,
            action: .webRootScroll(.dragged(Fixture.snapshot(offsetY: 14)))
        )

        XCTAssertEqual(rebound.presentation, .browsingMinimized)
        XCTAssertEqual(hidden.presentation, .browsingHidden)
    }

    func test_decelerationAfterDragEnd_doesNotChangeChrome() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let ended = sut.reduce(
            dragging,
            action: .webRootScroll(.dragEnded(Fixture.dragEnd(offsetY: 4, velocityY: 0)))
        )
        let decelerated = sut.reduce(
            ended,
            action: .webRootScroll(.decelerated(Fixture.snapshot(offsetY: 40)))
        )

        XCTAssertEqual(decelerated.presentation, .browsingMinimized)
        XCTAssertEqual(decelerated.interaction, .idle)
    }

    func test_topBarToggleAfterDragEnd_isAccepted_evenIfScrollViewIsDecelerating() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let ended = sut.reduce(
            dragging,
            action: .webRootScroll(.dragEnded(Fixture.dragEnd(offsetY: 4, velocityY: 0)))
        )
        let hidden = sut.reduce(ended, action: .topBarToggle)

        XCTAssertEqual(hidden.presentation, .browsingHidden)
    }

    func test_dragEndHighVelocity_hidesChromeOnce_forFastFlick() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let hidden = sut.reduce(
            dragging,
            action: .webRootScroll(.dragEnded(Fixture.dragEnd(offsetY: 4, velocityY: 1_600)))
        )
        let stillHidden = sut.reduce(
            hidden,
            action: .webRootScroll(.decelerated(Fixture.snapshot(offsetY: 60)))
        )

        XCTAssertEqual(hidden.presentation, .browsingHidden)
        XCTAssertEqual(stillHidden.presentation, .browsingHidden)
    }

    func test_dragEndHighVelocityUp_restoresChromeOnce_forFastFlick() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingHidden),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 40)))
        )
        let minimized = sut.reduce(
            dragging,
            action: .webRootScroll(.dragEnded(Fixture.dragEnd(offsetY: 40, velocityY: -1_600)))
        )
        let stillMinimized = sut.reduce(
            minimized,
            action: .webRootScroll(.decelerated(Fixture.snapshot(offsetY: 0)))
        )

        XCTAssertEqual(minimized.presentation, .browsingMinimized)
        XCTAssertEqual(stillMinimized.presentation, .browsingMinimized)
    }

    func test_dragEndOutOfBoundsWithHighVelocity_keepsChrome_andClearsInteraction() {
        let sut = SessionChromeReducer()
        let dragging = sut.reduce(
            Fixture.state(showing: .browsingMinimized),
            action: .webRootScroll(.dragBegan(Fixture.snapshot(offsetY: 0)))
        )
        let ended = sut.reduce(
            dragging,
            action: .webRootScroll(.dragEnded(Fixture.dragEnd(offsetY: -18, velocityY: 1_600)))
        )

        XCTAssertEqual(ended.presentation, .browsingMinimized)
        XCTAssertEqual(ended.interaction, .idle)
    }
}
