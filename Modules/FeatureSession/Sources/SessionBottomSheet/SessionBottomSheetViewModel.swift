//
//  SessionBottomSheetViewModel.swift
//  Clipy
//
//  Created by 박민서 on 5/31/26.
//

import RxCocoa
import RxSwift

/// Bottom Sheet의 상태를 소유하고 내부/외부 입력을 하나의 state output으로 정리합니다.
final class SessionBottomSheetViewModel {
    /// Bottom Sheet 상태를 바꿀 수 있는 외부 입력입니다.
    struct Input {
        /// Grabber drag 종료로 들어오는 사용자 action입니다.
        let dragEnded: Signal<SessionBottomSheetAction>
        /// Drag보다 우선해서 최종 반영해야 하는 직접 상태 요청입니다.
        let stateRequest: Signal<SessionBottomSheetState>
    }

    /// Bottom Sheet가 화면에 내보내는 상태 output입니다.
    struct Output {
        /// View가 렌더링해야 하는 현재 Bottom Sheet 상태입니다.
        let state: Driver<SessionBottomSheetState>
    }

    /// 여러 입력을 하나의 상태 변경 의도로 합친 값입니다.
    private enum Mutation {
        /// Drag action을 현재 상태 기준의 다음 상태로 해석합니다.
        case dragEnded(SessionBottomSheetAction)
        /// Drag 결과를 덮어쓸 수 있는 우선 상태 요청입니다.
        case stateRequested(SessionBottomSheetState)
    }

    /// Session 진입 시점에 사용할 최초 Bottom Sheet 상태입니다.
    private let initialState: SessionBottomSheetState
    /// Drag action을 다음 상태로 해석하는 전이 정책입니다.
    private let transitionPolicy: SessionBottomSheetTransitionPolicy

    /// 초기 상태와 drag 전이 정책을 주입합니다.
    init(
        initialState: SessionBottomSheetState = .peek,
        transitionPolicy: SessionBottomSheetTransitionPolicy = .standard
    ) {
        self.initialState = initialState
        self.transitionPolicy = transitionPolicy
    }

    /// Input stream을 Bottom Sheet state output으로 변환합니다.
    func transform(input: Input) -> Output {
        let dragMutations = input.dragEnded
            .map { Mutation.dragEnded($0) }

        let requestedStateMutations = input.stateRequest
            .map { Mutation.stateRequested($0) }

        // stateRequest는 같은 흐름의 drag 결과를 덮어쓰는 우선 mutation입니다.
        let state = Signal.merge(dragMutations, requestedStateMutations)
            .asObservable()
            .scan(initialState) { [transitionPolicy] state, mutation in
                Self.reduce(
                    state,
                    mutation: mutation,
                    transitionPolicy: transitionPolicy
                )
            }
            .startWith(initialState)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())

        return Output(state: state)
    }

    /// 현재 상태와 mutation을 이용해 다음 Bottom Sheet 상태를 계산합니다.
    private static func reduce(
        _ state: SessionBottomSheetState,
        mutation: Mutation,
        transitionPolicy: SessionBottomSheetTransitionPolicy
    ) -> SessionBottomSheetState {
        switch mutation {
        case .dragEnded(let action):
            return transitionPolicy.nextState(from: state, action: action)
        case .stateRequested(let requestedState):
            return requestedState
        }
    }
}
