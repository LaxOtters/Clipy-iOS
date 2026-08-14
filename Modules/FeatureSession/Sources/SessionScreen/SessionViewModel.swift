//
//  SessionViewModel.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

import RxCocoa

enum SessionRoute: Equatable {
    case home
}

/// Session 화면에서 들어온 입력을 화면이 구독할 output으로 바꿉니다.
/// Chrome 전환 판단은 reducer에 맡기고, ViewModel은 event 흐름을 연결하는 쪽에 둡니다.
final class SessionViewModel {
    struct Input {
        let viewDidLoad: Signal<Void>
        let homeTap: Signal<Void>
        let topBarToggleTap: Signal<Void>
        let webRootScroll: Signal<SessionWebRootScrollInput>
        /// 첫 navigation finish는 새 Session의 peek 상태를 유지하고, 그 다음 finish부터 browsing chrome으로 복원합니다.
        let browserNavigationFinished: Signal<Void>
        let bottomSheetDragEnded: Signal<SessionBottomSheetAction>
    }

    struct Output {
        let initialLoadURL: Signal<URL>
        /// 화면이 그대로 그릴 chrome 상태입니다.
        let chromeState: Driver<SessionChromeState>
        let route: Signal<SessionRoute>
    }

    private let context: SessionLaunchContext
    private let chromeReducer: SessionChromeReducer

    private static let defaultStartURL = URL(string: "https://google.com")!

    init(
        context: SessionLaunchContext,
        chromeReducer: SessionChromeReducer = SessionChromeReducer()
    ) {
        self.context = context
        self.chromeReducer = chromeReducer
    }

    func transform(input: Input) -> Output {
        let effectiveStartURL = context.initialURL ?? Self.defaultStartURL
        let initialLoadURL = input.viewDidLoad
            .map {
                effectiveStartURL
            }

        let chromeState = chromeActions(from: input)
            .asObservable()
            .scan(ChromeRenderAccumulator.initial) { [chromeReducer] accumulator, action in
                accumulator.reducing(action, reducer: chromeReducer)
            }
            .compactMap(\.renderedState)
            .startWith(.newSession)
            .asDriver(onErrorDriveWith: .empty())

        let route = input.homeTap
            .map { SessionRoute.home }

        return Output(
            initialLoadURL: initialLoadURL,
            chromeState: chromeState,
            route: route
        )
    }

    private func chromeActions(from input: Input) -> Signal<SessionChromeAction> {
        let topBarToggle = input.topBarToggleTap
            .map { SessionChromeAction.topBarToggle }

        let rootScroll = input.webRootScroll
            .map { SessionChromeAction.webRootScroll($0) }

        let bottomSheetDragEnded = input.bottomSheetDragEnded
            .map { SessionChromeAction.bottomSheetDragEnded($0) }

        let navigationAfterInitialLoad = input.browserNavigationFinished
            .asObservable()
            .scan(0) { count, _ in count + 1 }
            .compactMap { count -> SessionChromeAction? in
                guard count > 1 else {
                    return nil
                }

                return .navigationFinishedAfterInitialLoad
            }
            .asSignal(onErrorSignalWith: .empty())

        return Signal.merge(
            topBarToggle,
            rootScroll,
            bottomSheetDragEnded,
            navigationAfterInitialLoad
        )
    }
}

private struct ChromeRenderAccumulator {
    let reducerState: SessionChromeReducerState
    let renderedState: SessionChromeState?

    static let initial = ChromeRenderAccumulator(
        reducerState: .newSession,
        renderedState: nil
    )

    func reducing(
        _ action: SessionChromeAction,
        reducer: SessionChromeReducer
    ) -> ChromeRenderAccumulator {
        let nextState = reducer.reduce(reducerState, action: action)
        let shouldRender = nextState.presentation != reducerState.presentation
            || action.shouldRenderUnchangedPresentation

        return ChromeRenderAccumulator(
            reducerState: nextState,
            renderedState: shouldRender ? nextState.presentation : nil
        )
    }
}

private extension SessionChromeAction {
    var shouldRenderUnchangedPresentation: Bool {
        switch self {
        case .bottomSheetDragEnded:
            // 같은 detent로 돌아와도 손을 따라간 sheet는 원래 자리로 다시 붙여야 합니다.
            return true
        case .topBarToggle, .webRootScroll, .navigationFinishedAfterInitialLoad:
            return false
        }
    }
}
