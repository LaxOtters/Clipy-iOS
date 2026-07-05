//
//  SessionChromeState.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// Session 화면의 Top Bar와 Bottom Sheet를 한 chrome 상태로 묶습니다.
enum SessionChromeState: Equatable {
    case browsingHidden
    case browsingMinimized
    case comparingPeek(topBarState: SessionTopBarState)
    case comparingExpanded(topBarState: SessionTopBarState)

    static let newSession = SessionChromeState.comparingPeek(topBarState: .unfolded)

    var topBarState: SessionTopBarState {
        switch self {
        case .browsingHidden:
            return .folded
        case .browsingMinimized:
            return .unfolded
        case .comparingPeek(let topBarState), .comparingExpanded(let topBarState):
            return topBarState
        }
    }

    var bottomSheetState: SessionBottomSheetState {
        switch self {
        case .browsingHidden:
            return .hidden
        case .browsingMinimized:
            return .minimized
        case .comparingPeek:
            return .peek
        case .comparingExpanded:
            return .expanded
        }
    }
}
