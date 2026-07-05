//
//  SessionChromeInteraction.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// 사용자가 지금 어느 chrome 조작을 하고 있는지 나타냅니다.
/// WebView를 끌고 있는 동안에는 다른 chrome 입력이 끼어들지 않게 합니다.
enum SessionChromeInteraction: Equatable {
    case idle
    case webRootDragging(WebRootDragSession)

    var isWebRootDragging: Bool {
        switch self {
        case .idle:
            return false
        case .webRootDragging:
            return true
        }
    }
}
