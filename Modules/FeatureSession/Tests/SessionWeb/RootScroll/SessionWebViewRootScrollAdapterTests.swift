//
//  SessionWebViewRootScrollAdapterTests.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics
import XCTest

@testable import FeatureSession

final class SessionWebViewRootScrollAdapterTests: XCTestCase {
    func test_releaseVelocityY_usesTargetOffsetDirection_forPageDownFlick() {
        let velocityY = SessionWebRootScrollAdapter.contentVelocityY(
            releaseVelocityY: -1_600,
            targetOffsetY: 140,
            currentOffsetY: 20
        )

        XCTAssertEqual(velocityY, 1_600)
    }

    func test_releaseVelocityY_usesTargetOffsetDirection_forPageUpFlick() {
        let velocityY = SessionWebRootScrollAdapter.contentVelocityY(
            releaseVelocityY: 1_600,
            targetOffsetY: 20,
            currentOffsetY: 140
        )

        XCTAssertEqual(velocityY, -1_600)
    }

    func test_releaseVelocityY_returnsZero_whenProjectedOffsetDoesNotMove() {
        let velocityY = SessionWebRootScrollAdapter.contentVelocityY(
            releaseVelocityY: 1_600,
            targetOffsetY: 40,
            currentOffsetY: 40
        )

        XCTAssertEqual(velocityY, 0)
    }

    func test_endDraggingWithoutPreparedTargetOffset_returnsZeroVelocity_forNoFlickFallback() {
        let sut = SessionWebRootScrollAdapter()
        let snapshot = snapshot(offsetY: 20)

        _ = sut.beginDragging(snapshot: snapshot)
        let input = sut.endDragging(snapshot: snapshot)

        XCTAssertEqual(
            input,
            .dragEnded(SessionWebRootDragEndContext(snapshot: snapshot, velocityY: 0))
        )
    }

    func test_beginDraggingClearsPreparedVelocity_forInterruptedPreviousDrag() {
        let sut = SessionWebRootScrollAdapter()
        let snapshot = snapshot(offsetY: 20)

        _ = sut.beginDragging(snapshot: snapshot)
        sut.prepareDragEnd(
            releaseVelocityY: 1_600,
            targetOffsetY: 140,
            currentOffsetY: 20
        )
        _ = sut.beginDragging(snapshot: snapshot)
        let input = sut.endDragging(snapshot: snapshot)

        XCTAssertEqual(
            input,
            .dragEnded(SessionWebRootDragEndContext(snapshot: snapshot, velocityY: 0))
        )
    }

    func test_scrollInputAfterEndDragging_returnsExternalScroll_forProgrammaticFollowUp() {
        let sut = SessionWebRootScrollAdapter()
        let currentSnapshot = snapshot(offsetY: 20)
        let followUpSnapshot = snapshot(offsetY: 44)

        _ = sut.beginDragging(snapshot: currentSnapshot)
        _ = sut.endDragging(snapshot: currentSnapshot)
        let input = sut.scrollInput(snapshot: followUpSnapshot)

        XCTAssertEqual(input, .externalScroll(followUpSnapshot))
    }

    private func snapshot(offsetY: CGFloat) -> SessionWebRootScrollSnapshot {
        SessionWebRootScrollSnapshot(
            offsetY: offsetY,
            contentHeight: 1_200,
            viewportHeight: 800,
            adjustedContentInsetTop: 0,
            adjustedContentInsetBottom: 0
        )
    }
}
