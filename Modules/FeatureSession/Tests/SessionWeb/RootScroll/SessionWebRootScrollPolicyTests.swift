//
//  SessionWebRootScrollPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

final class SessionWebRootScrollPolicyTests: XCTestCase {
    func test_dragMovementBeyondThreshold_returnsDirectionAndEligibility_forScrollableRootPage() {
        let sut = SessionWebRootScrollPolicy()

        let movement = sut.movement(
            fromAnchorOffsetY: 20,
            to: snapshot(offsetY: 60)
        )

        XCTAssertEqual(movement, .init(direction: .down, isEligibleForChromeTransition: true))
    }

    func test_smallOffsetChange_returnsNil_forBounceNoise() {
        let sut = SessionWebRootScrollPolicy()

        let movement = sut.movement(
            fromAnchorOffsetY: 20,
            to: snapshot(offsetY: 27)
        )

        XCTAssertNil(movement)
    }

    func test_topRubberBand_returnsNil_forOutOfBoundsOffset() {
        let sut = SessionWebRootScrollPolicy()

        let movement = sut.movement(
            fromAnchorOffsetY: 4,
            to: snapshot(offsetY: -18)
        )

        XCTAssertNil(movement)
    }

    func test_bottomRubberBand_returnsNil_forOutOfBoundsOffset() {
        let sut = SessionWebRootScrollPolicy()

        let movement = sut.movement(
            fromAnchorOffsetY: 380,
            to: snapshot(offsetY: 430)
        )

        XCTAssertNil(movement)
    }

    func test_shortRootPage_returnsIneligibleMovement_forChromeReducerGuard() {
        let sut = SessionWebRootScrollPolicy()

        let movement = sut.movement(
            fromAnchorOffsetY: 0,
            to: snapshot(offsetY: 30, contentHeight: 900)
        )

        XCTAssertEqual(movement, .init(direction: .down, isEligibleForChromeTransition: false))
    }

    func test_fastFlickMovement_returnsDirectionOnce_fromDragEndVelocity() {
        let sut = SessionWebRootScrollPolicy()

        let down = sut.flickMovement(from: dragEnd(offsetY: 4, velocityY: 1_600))
        let up = sut.flickMovement(from: dragEnd(offsetY: 40, velocityY: -1_600))
        let slow = sut.flickMovement(from: dragEnd(offsetY: 4, velocityY: 800))

        XCTAssertEqual(down, .init(direction: .down, isEligibleForChromeTransition: true))
        XCTAssertEqual(up, .init(direction: .up, isEligibleForChromeTransition: true))
        XCTAssertNil(slow)
    }

    private func snapshot(
        offsetY: CGFloat,
        contentHeight: CGFloat = 1_200,
        viewportHeight: CGFloat = 800,
        adjustedContentInsetTop: CGFloat = 0,
        adjustedContentInsetBottom: CGFloat = 0
    ) -> SessionWebRootScrollSnapshot {
        SessionWebRootScrollSnapshot(
            offsetY: offsetY,
            contentHeight: contentHeight,
            viewportHeight: viewportHeight,
            adjustedContentInsetTop: adjustedContentInsetTop,
            adjustedContentInsetBottom: adjustedContentInsetBottom
        )
    }

    private func dragEnd(
        offsetY: CGFloat,
        velocityY: CGFloat
    ) -> SessionWebRootDragEndContext {
        SessionWebRootDragEndContext(
            snapshot: snapshot(offsetY: offsetY),
            velocityY: velocityY
        )
    }
}
