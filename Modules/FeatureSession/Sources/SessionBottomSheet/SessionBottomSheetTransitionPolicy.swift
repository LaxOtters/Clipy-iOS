//
//  SessionBottomSheetTransitionPolicy.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics

/// Bottom Sheet primitive에 들어온 사용자 action을 상태 전이로 해석합니다.
enum SessionBottomSheetAction: Equatable {
    case dragEnded(translationY: CGFloat, velocityY: CGFloat)
}

/// Bottom Sheet가 한 번의 drag로 한 단계씩 움직이도록 제한하는 정책입니다.
struct SessionBottomSheetTransitionPolicy: Equatable {
    static let standard = SessionBottomSheetTransitionPolicy(
        dragDistanceThreshold: 48,
        velocityThreshold: 500
    )

    let dragDistanceThreshold: CGFloat
    let velocityThreshold: CGFloat

    private enum DragDirection {
        case upward
        case downward
    }

    func nextState(
        from state: SessionBottomSheetState,
        action: SessionBottomSheetAction
    ) -> SessionBottomSheetState {
        switch action {
        case let .dragEnded(translationY, velocityY):
            guard let direction = dragDirection(translationY: translationY, velocityY: velocityY) else {
                return state
            }

            return nextState(from: state, direction: direction)
        }
    }

    private func dragDirection(translationY: CGFloat, velocityY: CGFloat) -> DragDirection? {
        if abs(velocityY) >= velocityThreshold {
            return velocityY < 0 ? .upward : .downward
        }

        if abs(translationY) >= dragDistanceThreshold {
            return translationY < 0 ? .upward : .downward
        }

        return nil
    }

    private func nextState(
        from state: SessionBottomSheetState,
        direction: DragDirection
    ) -> SessionBottomSheetState {
        switch (state, direction) {
        case (.hidden, .upward):
            return .peek
        case (.peek, .upward):
            return .expanded
        case (.expanded, .upward):
            return .expanded
        case (.hidden, .downward):
            return .hidden
        case (.peek, .downward):
            return .hidden
        case (.expanded, .downward):
            return .peek
        }
    }
}

/// 현재 Bottom Sheet 상태를 보관하고 policy 결과를 적용합니다.
struct SessionBottomSheetStateMachine: Equatable {
    private(set) var currentState: SessionBottomSheetState
    private let policy: SessionBottomSheetTransitionPolicy

    init(
        initialState: SessionBottomSheetState = .hidden,
        policy: SessionBottomSheetTransitionPolicy = .standard
    ) {
        currentState = initialState
        self.policy = policy
    }

    mutating func handle(_ action: SessionBottomSheetAction) -> SessionBottomSheetState {
        let nextState = policy.nextState(from: currentState, action: action)
        currentState = nextState
        return nextState
    }
}
