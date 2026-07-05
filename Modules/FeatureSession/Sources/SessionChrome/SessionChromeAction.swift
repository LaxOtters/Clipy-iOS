//
//  SessionChromeAction.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// Session chrome을 바꿀 수 있는 입력을 reducer가 읽는 형태로 모읍니다.
enum SessionChromeAction: Equatable {
    case topBarToggle
    case webRootScroll(SessionWebRootScrollInput)
    case bottomSheetDragEnded(SessionBottomSheetAction)
    case navigationFinishedAfterInitialLoad
}
