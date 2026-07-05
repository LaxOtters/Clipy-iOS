//
//  SessionWebRootScrollInput.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// UIScrollView 전체를 넘기지 않고 chrome 전이에 필요한 위치와 page 크기만 남긴 값입니다.
struct SessionWebRootScrollSnapshot: Equatable {
    let offsetY: CGFloat
    let contentHeight: CGFloat
    let viewportHeight: CGFloat
    let adjustedContentInsetTop: CGFloat
    let adjustedContentInsetBottom: CGFloat
}

/// 사용자가 WebView drag를 끝낸 순간 reducer가 한 번만 flick를 판단할 때 쓰는 입력입니다.
struct SessionWebRootDragEndContext: Equatable {
    let snapshot: SessionWebRootScrollSnapshot
    /// content offset 기준 속도입니다. 양수면 page down, 음수면 page up 방향입니다.
    let velocityY: CGFloat
}

/// WebKit/UIScrollView callback을 FeatureSession 안에서 다루기 좋게 바꾼 lifecycle input입니다.
enum SessionWebRootScrollInput: Equatable {
    case dragBegan(SessionWebRootScrollSnapshot)
    case dragged(SessionWebRootScrollSnapshot)
    case dragEnded(SessionWebRootDragEndContext)
    case decelerated(SessionWebRootScrollSnapshot)
    case externalScroll(SessionWebRootScrollSnapshot)
}
