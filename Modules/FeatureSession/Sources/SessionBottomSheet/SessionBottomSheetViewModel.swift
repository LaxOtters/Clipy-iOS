//
//  SessionBottomSheetViewModel.swift
//  Clipy
//
//  Created by 박민서 on 5/31/26.
//

import RxCocoa
import RxSwift

final class SessionBottomSheetViewModel {
    struct Input {
        /// grabber에서 끝난 drag 입력입니다.
        let dragEnded: Signal<SessionBottomSheetAction>
        /// 내부/외부에서 직접 요청한 Bottom Sheet state입니다.
        let stateRequest: Signal<SessionBottomSheetState>
    }

    struct Output {
        /// View가 snap animation까지 다시 실행해야 하는 render state입니다. 같은 state도 다시 방출될 수 있습니다.
        let renderState: Driver<SessionBottomSheetState>
    }

    private enum Mutation {
        /// drag action을 현재 state 기준 target state로 바꾸는 입력입니다.
        case dragEnded(SessionBottomSheetAction)
        /// 요청된 state를 policy 계산 없이 바로 반영하는 입력입니다.
        case stateRequested(SessionBottomSheetState)
    }

    private let initialState: SessionBottomSheetState
    private let policy: SessionBottomSheetPolicy

    init(
        initialState: SessionBottomSheetState = .peek,
        policy: SessionBottomSheetPolicy = .standard
    ) {
        self.initialState = initialState
        self.policy = policy
    }

    func transform(input: Input) -> Output {
        let dragMutations = input.dragEnded
            .map { Mutation.dragEnded($0) }

        let requestedStateMutations = input.stateRequest
            .map { Mutation.stateRequested($0) }

        let renderState = Signal.merge(
            dragMutations,
            requestedStateMutations
        )
            .asObservable()
            .scan(initialState) { [policy] state, mutation in
                Self.reduce(
                    state,
                    mutation: mutation,
                    policy: policy
                )
            }
            .startWith(initialState)
            .asDriver(onErrorDriveWith: .empty())

        return Output(renderState: renderState)
    }

    private static func reduce(
        _ state: SessionBottomSheetState,
        mutation: Mutation,
        policy: SessionBottomSheetPolicy
    ) -> SessionBottomSheetState {
        switch mutation {
        case .dragEnded(let action):
            return policy.nextState(from: state, action: action)
        case .stateRequested(let requestedState):
            return requestedState
        }
    }
}
