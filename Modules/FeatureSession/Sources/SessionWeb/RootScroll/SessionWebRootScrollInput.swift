//
//  SessionWebRootScrollInput.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import CoreGraphics

/// WebView root scroll을 chrome 판단에 필요한 값으로 줄인 snapshot입니다.
struct SessionWebRootScrollSnapshot: Equatable {
    let offsetY: CGFloat
    let contentHeight: CGFloat
    let viewportHeight: CGFloat
    let adjustedContentInsetTop: CGFloat
    let adjustedContentInsetBottom: CGFloat
}

/// 손을 뗀 순간의 위치와 속도로 flick 의도를 한 번만 판단하게 해주는 입력입니다.
struct SessionWebRootDragEndContext: Equatable {
    let snapshot: SessionWebRootScrollSnapshot
    /// content offset 기준 속도입니다. 양수면 page down, 음수면 page up입니다.
    let velocityY: CGFloat
}

/// UIKit scroll callback을 Session chrome이 읽을 수 있는 drag lifecycle로 바꾼 입력입니다.
enum SessionWebRootScrollInput: Equatable {
    case dragBegan(SessionWebRootScrollSnapshot)
    case dragged(SessionWebRootScrollSnapshot)
    case dragEnded(SessionWebRootDragEndContext)
    case decelerated(SessionWebRootScrollSnapshot)
    case externalScroll(SessionWebRootScrollSnapshot)
}
