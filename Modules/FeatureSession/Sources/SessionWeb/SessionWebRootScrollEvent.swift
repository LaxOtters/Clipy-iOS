//
//  SessionWebRootScrollEvent.swift
//  Clipy
//
//  Created by 박민서 on 6/27/26.
//

/// Chrome 전환에서 보는 WebView root scroll 방향입니다.
enum SessionWebRootScrollDirection: Equatable {
    case up
    case down
}

/// `SessionWebView`가 scroll offset을 chrome 전환용 값으로 줄여서 넘깁니다.
struct SessionWebRootScrollEvent: Equatable {
    let direction: SessionWebRootScrollDirection
    let isEligibleForChromeTransition: Bool
}
