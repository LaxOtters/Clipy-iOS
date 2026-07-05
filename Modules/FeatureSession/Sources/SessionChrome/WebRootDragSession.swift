//
//  WebRootDragSession.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// WebView drag 한 번 동안 마지막 유효 offset을 잡아 threshold를 누적 판단합니다.
struct WebRootDragSession: Equatable {
    private var anchorOffsetY: CGFloat?

    init(anchorOffsetY: CGFloat?) {
        self.anchorOffsetY = anchorOffsetY
    }

    mutating func movement(
        for snapshot: SessionWebRootScrollSnapshot,
        policy: SessionWebRootScrollPolicy
    ) -> SessionWebRootScrollMovement? {
        guard policy.isInsideScrollableBounds(snapshot) else {
            anchorOffsetY = nil
            return nil
        }

        guard let anchorOffsetY else {
            self.anchorOffsetY = snapshot.offsetY
            return nil
        }

        guard let movement = policy.movement(
            fromAnchorOffsetY: anchorOffsetY,
            to: snapshot
        ) else {
            return nil
        }

        self.anchorOffsetY = snapshot.offsetY
        return movement
    }
}
