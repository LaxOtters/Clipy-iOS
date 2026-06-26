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
