//
//  SessionWebRootScrollAdapter.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// WebView scroll callback을 Session 쪽에서 읽기 쉬운 drag 흐름으로 바꿉니다.
/// UIKit callback 순서와 flick 방향만 정리하고, chrome을 바꿀지는 판단하지 않습니다.
final class SessionWebRootScrollAdapter {
    private var isDragging = false
    private var pendingDragEndContentVelocityY: CGFloat?

    func beginDragging(snapshot: SessionWebRootScrollSnapshot) -> SessionWebRootScrollInput {
        isDragging = true
        pendingDragEndContentVelocityY = nil
        return .dragBegan(snapshot)
    }

    func scrollInput(snapshot: SessionWebRootScrollSnapshot) -> SessionWebRootScrollInput {
        guard isDragging else {
            return .externalScroll(snapshot)
        }

        return .dragged(snapshot)
    }

    func prepareDragEnd(
        releaseVelocityY: CGFloat,
        targetOffsetY: CGFloat,
        currentOffsetY: CGFloat
    ) {
        pendingDragEndContentVelocityY = Self.contentVelocityY(
            releaseVelocityY: releaseVelocityY,
            targetOffsetY: targetOffsetY,
            currentOffsetY: currentOffsetY
        )
    }

    func endDragging(
        snapshot: SessionWebRootScrollSnapshot
    ) -> SessionWebRootScrollInput {
        defer {
            isDragging = false
            pendingDragEndContentVelocityY = nil
        }

        return .dragEnded(
            SessionWebRootDragEndContext(
                snapshot: snapshot,
                velocityY: pendingDragEndContentVelocityY ?? 0
            )
        )
    }

    /// 손을 뗀 순간에는 UIKit velocity 부호보다 예상 target offset 차이가 page 방향을 더 직접적으로 보여줍니다.
    static func contentVelocityY(
        releaseVelocityY: CGFloat,
        targetOffsetY: CGFloat,
        currentOffsetY: CGFloat
    ) -> CGFloat {
        let projectedDeltaY = targetOffsetY - currentOffsetY
        guard projectedDeltaY != 0 else {
            return 0
        }

        let speed = abs(releaseVelocityY)
        return projectedDeltaY > 0 ? speed : -speed
    }
}
