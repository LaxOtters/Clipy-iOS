//
//  SessionChromeAction.swift
//  Clipy
//
//  Created by 박민서 on 6/27/26.
//

/// `SessionViewModel`이 chrome reducer에 넣는 action입니다.
enum SessionChromeAction: Equatable {
    case topBarToggle
    case webRootScroll(SessionWebRootScrollEvent)
    case bottomSheetDragEnded(SessionBottomSheetAction)
    case navigationFinishedAfterInitialLoad
}
