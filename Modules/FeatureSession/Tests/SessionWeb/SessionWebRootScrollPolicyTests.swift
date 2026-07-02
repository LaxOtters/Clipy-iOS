//
//  SessionWebRootScrollPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 6/26/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

final class SessionWebRootScrollPolicyTests: XCTestCase {
    func test_userScrollBeyondThreshold_emitsDirectionAndEligibility_forScrollableRootPage() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 20,
            currentOffsetY: 60,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertEqual(event, .init(direction: .down, isEligibleForChromeTransition: true))
    }

    func test_smallOffsetChange_returnsNil_forBounceNoise() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 20,
            currentOffsetY: 27,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertNil(event)
    }

    func test_programmaticOffsetChange_returnsNil_becauseItIsNotUserChromeIntent() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 20,
            currentOffsetY: 80,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: false
        )

        XCTAssertNil(event)
    }

    func test_topRubberBand_returnsNil_forOutOfBoundsOffset() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 4,
            currentOffsetY: -18,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertNil(event)
    }

    func test_bottomRubberBand_returnsNil_forOutOfBoundsOffset() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 380,
            currentOffsetY: 430,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertNil(event)
    }

    func test_shortRootPage_emitsIneligibleEvent_forChromePolicyGuard() {
        let sut = SessionWebRootScrollPolicy()

        let event = sut.event(
            previousOffsetY: 0,
            currentOffsetY: 30,
            contentHeight: 900,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertEqual(event, .init(direction: .down, isEligibleForChromeTransition: false))
    }
}

final class SessionWebRootScrollTrackerTests: XCTestCase {
    func test_slowRootScroll_emitsEvent_whenAccumulatedMovementPassesThreshold() {
        var sut = SessionWebRootScrollTracker()

        let events = [0, 4, 8, 13].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        XCTAssertEqual(events, [.init(direction: .down, isEligibleForChromeTransition: true)])
    }

    func test_slowRootScrollUp_emitsEvent_whenAccumulatedMovementPassesThreshold() {
        var sut = SessionWebRootScrollTracker()

        let events = [80, 76, 72, 67].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        XCTAssertEqual(events, [.init(direction: .up, isEligibleForChromeTransition: true)])
    }

    func test_smallBackAndForthMovement_returnsNil_forBounceNoise() {
        var sut = SessionWebRootScrollTracker()

        let events = [0, 4, -3, 5, -4].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        XCTAssertTrue(events.isEmpty)
    }

    func test_emittedEvent_movesAnchor_forNextSlowRootScroll() {
        var sut = SessionWebRootScrollTracker()

        _ = [0, 6, 13].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        let events = [18, 22, 26].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        XCTAssertEqual(events, [.init(direction: .down, isEligibleForChromeTransition: true)])
    }

    func test_resetBreaksAccumulation_betweenSlowGestures() {
        var sut = SessionWebRootScrollTracker()

        _ = [0, 4, 8].compactMap { offsetY in
            sut.event(
                currentOffsetY: CGFloat(offsetY),
                contentHeight: 1_200,
                viewportHeight: 800,
                adjustedContentInsetTop: 0,
                adjustedContentInsetBottom: 0,
                isUserInteracting: true
            )
        }

        sut.reset(anchorOffsetY: 8)

        let event = sut.event(
            currentOffsetY: 13,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertNil(event)
    }

    func test_decelerationKeepsAccumulation_forFastFlickScroll() {
        var sut = SessionWebRootScrollTracker()

        _ = sut.event(
            currentOffsetY: 0,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )
        _ = sut.event(
            currentOffsetY: 8,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        let event = sut.event(
            currentOffsetY: 14,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertEqual(event, .init(direction: .down, isEligibleForChromeTransition: true))
    }

    func test_programmaticOffsetChange_resetsAnchor_forNextUserScroll() {
        var sut = SessionWebRootScrollTracker()

        _ = sut.event(
            currentOffsetY: 0,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )
        _ = sut.event(
            currentOffsetY: 80,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: false
        )

        let event = sut.event(
            currentOffsetY: 86,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0,
            isUserInteracting: true
        )

        XCTAssertNil(event)
    }
}
