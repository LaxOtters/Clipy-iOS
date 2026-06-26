//
//  SessionChromePolicy.swift
//  Clipy
//
//  Created by 박민서 on 6/27/26.
//

/// Top Bar, root scroll, Bottom Sheet drag를 같은 chrome 전이 규칙으로 모읍니다.
/// Root scroll은 browsing 상태에서만 chrome을 접거나 펼칩니다.
struct SessionChromePolicy: Equatable {
    let bottomSheetPolicy: SessionBottomSheetPolicy

    init(bottomSheetPolicy: SessionBottomSheetPolicy = .standard) {
        self.bottomSheetPolicy = bottomSheetPolicy
    }

    func nextState(
        from state: SessionChromeState,
        action: SessionChromeAction
    ) -> SessionChromeState {
        switch action {
        case .topBarToggle:
            return nextStateByTogglingTopBar(from: state)
        case .webRootScroll(let event):
            return nextStateByRootScroll(from: state, event: event)
        case .bottomSheetDragEnded(let action):
            return nextStateByDraggingBottomSheet(from: state, action: action)
        case .navigationFinishedAfterInitialLoad:
            return .browsingMinimized
        }
    }

    private func nextStateByTogglingTopBar(from state: SessionChromeState) -> SessionChromeState {
        switch state {
        case .browsingHidden:
            return .browsingMinimized
        case .browsingMinimized:
            return .browsingHidden
        case .comparingPeek(let topBarState):
            return .comparingPeek(topBarState: topBarState.toggled)
        case .comparingExpanded(let topBarState):
            return .comparingExpanded(topBarState: topBarState.toggled)
        }
    }

    private func nextStateByRootScroll(
        from state: SessionChromeState,
        event: SessionWebRootScrollEvent
    ) -> SessionChromeState {
        guard event.isEligibleForChromeTransition else {
            return state
        }

        switch (state, event.direction) {
        case (.browsingMinimized, .down):
            return .browsingHidden
        case (.browsingHidden, .up):
            return .browsingMinimized
        default:
            return state
        }
    }

    private func nextStateByDraggingBottomSheet(
        from state: SessionChromeState,
        action: SessionBottomSheetAction
    ) -> SessionChromeState {
        let nextBottomSheetState = bottomSheetPolicy.nextState(
            from: state.bottomSheetState,
            action: action
        )

        switch nextBottomSheetState {
        case .hidden:
            return .browsingHidden
        case .minimized:
            return .browsingMinimized
        case .peek:
            return .comparingPeek(topBarState: state.topBarState)
        case .expanded:
            return .comparingExpanded(topBarState: state.topBarState)
        }
    }
}
