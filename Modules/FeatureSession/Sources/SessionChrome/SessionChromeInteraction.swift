//
//  SessionChromeInteraction.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// Web root drag 중 다른 chrome 입력을 막기 위해 현재 조작 주체를 기록합니다.
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
