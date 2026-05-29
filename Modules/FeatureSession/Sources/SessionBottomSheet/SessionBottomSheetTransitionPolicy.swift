//
//  SessionBottomSheetTransitionPolicy.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics

/// Bottom Sheet primitive에 들어온 사용자 action을 상태 전이로 해석합니다.
enum SessionBottomSheetAction: Equatable {
    /// Drag가 끝났을 때의 이동 거리와 속도를 전달합니다.
    case dragEnded(translationY: CGFloat, velocityY: CGFloat)
}

/// Bottom Sheet가 한 번의 drag로 한 단계씩 움직이도록 제한하는 정책입니다.
struct SessionBottomSheetTransitionPolicy: Equatable {
    /// 현재 primitive에서 사용하는 기본 drag 전이 기준입니다.
    static let standard = SessionBottomSheetTransitionPolicy(
        dragDistanceThreshold: 48,
        velocityThreshold: 500
    )

    /// 상태 전이를 시작하는 최소 drag 거리입니다.
    let dragDistanceThreshold: CGFloat
    /// 상태 전이를 시작하는 최소 drag 속도입니다.
    let velocityThreshold: CGFloat

    /// Drag가 위쪽 이동인지 아래쪽 이동인지 나타냅니다.
    private enum DragDirection {
        case upward
        case downward
    }

    /// 현재 상태와 사용자 action을 받아 다음 Bottom Sheet 상태를 반환합니다.
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

    /// Drag 거리와 속도 중 먼저 기준을 넘는 값을 이용해 이동 방향을 해석합니다.
    private func dragDirection(translationY: CGFloat, velocityY: CGFloat) -> DragDirection? {
        if abs(velocityY) >= velocityThreshold {
            return velocityY < 0 ? .upward : .downward
        }

        if abs(translationY) >= dragDistanceThreshold {
            return translationY < 0 ? .upward : .downward
        }

        return nil
    }

    /// 현재 상태에서 한 번의 drag 방향으로 이동할 수 있는 다음 상태를 반환합니다.
    private func nextState(
        from state: SessionBottomSheetState,
        direction: DragDirection
    ) -> SessionBottomSheetState {
        switch (state, direction) {
        case (.minimized, .upward):
            return .hidden
        case (.hidden, .upward):
            return .peek
        case (.peek, .upward):
            return .expanded
        case (.expanded, .upward):
            return .expanded
        case (.minimized, .downward):
            return .minimized
        case (.hidden, .downward):
            return .minimized
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
