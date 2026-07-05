//
//  SessionWebRootScrollPolicy.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// Root scroll이 chrome 전환에 쓸 수 있는 방향과 page 조건을 계산합니다.
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
        // rubber-band offset은 실제 page 이동이 아니어서 chrome 전이 신호에서 빼둡니다.
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

/// Chrome reducer가 presentation 전이를 판단할 때 쓰는 root scroll movement입니다.
struct SessionWebRootScrollMovement: Equatable {
    let direction: SessionWebRootScrollDirection
    let isEligibleForChromeTransition: Bool
}

enum SessionWebRootScrollDirection: Equatable {
    case up
    case down
}
