//
//  SessionWebRootScrollPolicy.swift
//  Clipy
//
//  Created by 박민서 on 6/26/26.
//

import CoreGraphics

/// WebView scroll 중 chrome 전환 판단에 쓸 root scroll event만 걸러냅니다.
struct SessionWebRootScrollPolicy: Equatable {
    private let bounceThreshold: CGFloat
    private let minimumScrollableViewportRatio: CGFloat

    init(
        bounceThreshold: CGFloat = 12,
        minimumScrollableViewportRatio: CGFloat = 0.20
    ) {
        self.bounceThreshold = bounceThreshold
        self.minimumScrollableViewportRatio = minimumScrollableViewportRatio
    }

    func event(
        previousOffsetY: CGFloat,
        currentOffsetY: CGFloat,
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        adjustedContentInsetTop: CGFloat,
        adjustedContentInsetBottom: CGFloat,
        isUserInteracting: Bool
    ) -> SessionWebRootScrollEvent? {
        let deltaY = currentOffsetY - previousOffsetY
        guard abs(deltaY) >= bounceThreshold else {
            return nil
        }

        // load/restore offset과 rubber-band는 사용자가 chrome 상태를 바꾸려는 신호로 보지 않습니다.
        guard isUserInteracting,
              isInsideScrollableBounds(
                currentOffsetY: currentOffsetY,
                contentHeight: contentHeight,
                viewportHeight: viewportHeight,
                adjustedContentInsetTop: adjustedContentInsetTop,
                adjustedContentInsetBottom: adjustedContentInsetBottom
              ) else {
            return nil
        }

        return SessionWebRootScrollEvent(
            direction: deltaY > 0 ? .down : .up,
            isEligibleForChromeTransition: isEligibleForChromeTransition(
                contentHeight: contentHeight,
                viewportHeight: viewportHeight,
                adjustedContentInsetTop: adjustedContentInsetTop,
                adjustedContentInsetBottom: adjustedContentInsetBottom
            )
        )
    }

    private func isInsideScrollableBounds(
        currentOffsetY: CGFloat,
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        adjustedContentInsetTop: CGFloat,
        adjustedContentInsetBottom: CGFloat
    ) -> Bool {
        let minimumOffsetY = -max(adjustedContentInsetTop, 0)
        let maximumOffsetY = max(
            minimumOffsetY,
            max(contentHeight, 0) - max(viewportHeight, 0) + max(adjustedContentInsetBottom, 0)
        )

        return currentOffsetY >= minimumOffsetY && currentOffsetY <= maximumOffsetY
    }

    private func isEligibleForChromeTransition(
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        adjustedContentInsetTop: CGFloat,
        adjustedContentInsetBottom: CGFloat
    ) -> Bool {
        let viewportHeight = max(viewportHeight, 0)
        let scrollableHeight = max(
            contentHeight + adjustedContentInsetTop + adjustedContentInsetBottom - viewportHeight,
            0
        )
        return scrollableHeight >= viewportHeight * minimumScrollableViewportRatio
    }
}
