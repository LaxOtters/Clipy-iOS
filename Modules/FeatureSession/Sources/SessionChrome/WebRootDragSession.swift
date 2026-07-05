//
//  WebRootDragSession.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// WebView를 한 번 끄는 동안 어디서부터 얼마나 움직였는지 기억합니다.
/// 천천히 끌거나 edge에서 튕겨도 chrome 전환 의도만 읽을 수 있게 anchor를 잡아줍니다.
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
