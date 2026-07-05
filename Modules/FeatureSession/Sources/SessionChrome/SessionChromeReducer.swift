//
//  SessionChromeReducer.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// Top Bar, WebView root scroll, Bottom Sheet drag를 하나의 chrome 상태 전이로 모읍니다.
struct SessionChromeReducer: Equatable {
    let bottomSheetPolicy: SessionBottomSheetPolicy
    let rootScrollPolicy: SessionWebRootScrollPolicy

    init(
        bottomSheetPolicy: SessionBottomSheetPolicy = .standard,
        rootScrollPolicy: SessionWebRootScrollPolicy = SessionWebRootScrollPolicy()
    ) {
        self.bottomSheetPolicy = bottomSheetPolicy
        self.rootScrollPolicy = rootScrollPolicy
    }

    func reduce(
        _ state: SessionChromeReducerState,
        action: SessionChromeAction
    ) -> SessionChromeReducerState {
        switch action {
        case .topBarToggle:
            return reduceTopBarToggle(state)
        case .webRootScroll(let input):
            return reduceWebRootScroll(state, input: input)
        case .bottomSheetDragEnded(let action):
            return reduceBottomSheetDragEnded(state, action: action)
        case .navigationFinishedAfterInitialLoad:
            return state.updatingPresentation(.browsingMinimized)
        }
    }

    private func reduceTopBarToggle(
        _ state: SessionChromeReducerState
    ) -> SessionChromeReducerState {
        guard !state.interaction.isWebRootDragging else {
            return state
        }

        switch state.presentation {
        case .browsingHidden:
            return state.updatingPresentation(.browsingMinimized)
        case .browsingMinimized:
            return state.updatingPresentation(.browsingHidden)
        case .comparingPeek(let topBarState):
            return state.updatingPresentation(.comparingPeek(topBarState: topBarState.toggled))
        case .comparingExpanded(let topBarState):
            return state.updatingPresentation(.comparingExpanded(topBarState: topBarState.toggled))
        }
    }

    private func reduceWebRootScroll(
        _ state: SessionChromeReducerState,
        input: SessionWebRootScrollInput
    ) -> SessionChromeReducerState {
        switch input {
        case .dragBegan(let snapshot):
            let anchorOffsetY = rootScrollPolicy.isInsideScrollableBounds(snapshot) ? snapshot.offsetY : nil
            return state.updatingInteraction(.webRootDragging(WebRootDragSession(anchorOffsetY: anchorOffsetY)))
        case .dragged(let snapshot):
            return reduceWebRootDragged(state, snapshot: snapshot)
        case .dragEnded(let context):
            return reduceWebRootDragEnded(state, context: context)
        case .decelerated:
            return state.updatingInteraction(.idle)
        case .externalScroll:
            return state
        }
    }

    private func reduceWebRootDragged(
        _ state: SessionChromeReducerState,
        snapshot: SessionWebRootScrollSnapshot
    ) -> SessionChromeReducerState {
        guard case .webRootDragging(var session) = state.interaction else {
            return state
        }

        let movement = session.movement(for: snapshot, policy: rootScrollPolicy)
        return state
            .updatingInteraction(.webRootDragging(session))
            .applyingRootScrollMovement(movement)
    }

    private func reduceWebRootDragEnded(
        _ state: SessionChromeReducerState,
        context: SessionWebRootDragEndContext
    ) -> SessionChromeReducerState {
        guard case .webRootDragging(var session) = state.interaction else {
            return state.updatingInteraction(.idle)
        }

        let dragMovement = session.movement(for: context.snapshot, policy: rootScrollPolicy)
        let flickMovement = dragMovement == nil ? rootScrollPolicy.flickMovement(from: context) : nil

        return state
            .updatingInteraction(.idle)
            .applyingRootScrollMovement(dragMovement ?? flickMovement)
    }

    private func reduceBottomSheetDragEnded(
        _ state: SessionChromeReducerState,
        action: SessionBottomSheetAction
    ) -> SessionChromeReducerState {
        let nextBottomSheetState = bottomSheetPolicy.nextState(
            from: state.presentation.bottomSheetState,
            action: action
        )

        return state
            .updatingInteraction(.idle)
            .updatingPresentation(presentation(for: nextBottomSheetState, topBarState: state.presentation.topBarState))
    }

    private func presentation(
        for bottomSheetState: SessionBottomSheetState,
        topBarState: SessionTopBarState
    ) -> SessionChromeState {
        switch bottomSheetState {
        case .hidden:
            return .browsingHidden
        case .minimized:
            return .browsingMinimized
        case .peek:
            return .comparingPeek(topBarState: topBarState)
        case .expanded:
            return .comparingExpanded(topBarState: topBarState)
        }
    }
}

private extension SessionChromeReducerState {
    func updatingPresentation(_ presentation: SessionChromeState) -> SessionChromeReducerState {
        var state = self
        state.presentation = presentation
        return state
    }

    func updatingInteraction(_ interaction: SessionChromeInteraction) -> SessionChromeReducerState {
        var state = self
        state.interaction = interaction
        return state
    }

    func applyingRootScrollMovement(
        _ movement: SessionWebRootScrollMovement?
    ) -> SessionChromeReducerState {
        guard let movement,
              movement.isEligibleForChromeTransition else {
            return self
        }

        switch (presentation, movement.direction) {
        case (.browsingMinimized, .down):
            return updatingPresentation(.browsingHidden)
        case (.browsingHidden, .up):
            return updatingPresentation(.browsingMinimized)
        default:
            return self
        }
    }
}
