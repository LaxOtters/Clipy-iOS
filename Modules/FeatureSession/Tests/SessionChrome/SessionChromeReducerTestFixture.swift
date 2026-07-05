//
//  SessionChromeReducerTestFixture.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

@testable import FeatureSession

enum SessionChromeReducerTestFixture {
    static func state(showing presentation: SessionChromeState) -> SessionChromeReducerState {
        SessionChromeReducerState(
            presentation: presentation,
            interaction: .idle
        )
    }

    static func draggingState(showing presentation: SessionChromeState) -> SessionChromeReducerState {
        SessionChromeReducerState(
            presentation: presentation,
            interaction: .webRootDragging(WebRootDragSession(anchorOffsetY: 0))
        )
    }

    static func snapshot(
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

    static func dragEnd(
        offsetY: CGFloat,
        velocityY: CGFloat
    ) -> SessionWebRootDragEndContext {
        SessionWebRootDragEndContext(
            snapshot: snapshot(offsetY: offsetY),
            velocityY: velocityY
        )
    }

    static func bottomSheetDragEnded(
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
