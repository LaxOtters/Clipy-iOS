//
//  SessionWebRootScrollPolicy.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// WebView root scroll이 chrome 전환 신호로 볼 만한 움직임인지 계산합니다.
/// 짧은 page, rubber-band, 약한 flick처럼 화면 의도로 보기 어려운 움직임을 걸러냅니다.
struct SessionWebRootScrollPolicy: Equatable {
    private let dragThreshold: CGFloat
    private let flickVelocityThreshold: CGFloat
    private let minimumScrollableViewportRatio: CGFloat

    init(
        dragThreshold: CGFloat = 12,
        flickVelocityThreshold: CGFloat = 1_200,
        minimumScrollableViewportRatio: CGFloat = 0.20
    ) {
        self.dragThreshold = dragThreshold
        self.flickVelocityThreshold = flickVelocityThreshold
        self.minimumScrollableViewportRatio = minimumScrollableViewportRatio
    }

    func movement(
        fromAnchorOffsetY anchorOffsetY: CGFloat,
        to snapshot: SessionWebRootScrollSnapshot
    ) -> SessionWebRootScrollMovement? {
        guard isInsideScrollableBounds(snapshot) else {
            return nil
        }

        let deltaY = snapshot.offsetY - anchorOffsetY
        guard abs(deltaY) >= dragThreshold else {
            return nil
        }

        return SessionWebRootScrollMovement(
            direction: deltaY > 0 ? .down : .up,
            isEligibleForChromeTransition: isEligibleForChromeTransition(snapshot)
        )
    }

    func flickMovement(
        from context: SessionWebRootDragEndContext
    ) -> SessionWebRootScrollMovement? {
        guard isInsideScrollableBounds(context.snapshot),
              abs(context.velocityY) >= flickVelocityThreshold else {
            return nil
        }

        return SessionWebRootScrollMovement(
            direction: context.velocityY > 0 ? .down : .up,
            isEligibleForChromeTransition: isEligibleForChromeTransition(context.snapshot)
        )
    }

    func isInsideScrollableBounds(_ snapshot: SessionWebRootScrollSnapshot) -> Bool {
        // rubber-band는 page를 읽는 움직임이 아니라 edge에서 튕긴 값이라 chrome 신호에서 뺍니다.
        let minimumOffsetY = -max(snapshot.adjustedContentInsetTop, 0)
        let maximumOffsetY = max(
            minimumOffsetY,
            max(snapshot.contentHeight, 0) - max(snapshot.viewportHeight, 0) + max(snapshot.adjustedContentInsetBottom, 0)
        )

        return snapshot.offsetY >= minimumOffsetY && snapshot.offsetY <= maximumOffsetY
    }

    private func isEligibleForChromeTransition(_ snapshot: SessionWebRootScrollSnapshot) -> Bool {
        let viewportHeight = max(snapshot.viewportHeight, 0)
        let scrollableHeight = max(
            snapshot.contentHeight + snapshot.adjustedContentInsetTop + snapshot.adjustedContentInsetBottom - viewportHeight,
            0
        )
        return scrollableHeight >= viewportHeight * minimumScrollableViewportRatio
    }
}

/// Reducer가 chrome 전환 후보로 읽는 root scroll 움직임입니다.
struct SessionWebRootScrollMovement: Equatable {
    let direction: SessionWebRootScrollDirection
    let isEligibleForChromeTransition: Bool
}

enum SessionWebRootScrollDirection: Equatable {
    case up
    case down
}
