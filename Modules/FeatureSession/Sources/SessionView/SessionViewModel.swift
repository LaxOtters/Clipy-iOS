//
//  SessionViewModel.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

import RxCocoa

/// Session 화면에서 사용자가 의도한 화면 이동을 표현합니다.
enum SessionRoute: Equatable {
    /// Session 화면을 닫고 Home으로 돌아갑니다.
    case home
}

/// Session 진입과 chrome event를 URL load, chrome state, route output으로 바꿉니다.
final class SessionViewModel {
    struct Input {
        /// 화면 최초 진입 시 초기 URL load를 시작하는 lifecycle event입니다.
        let viewDidLoad: Signal<Void>
        /// Home button tap으로 들어오는 화면 종료 event입니다.
        let homeTap: Signal<Void>
        let topBarToggleTap: Signal<Void>
        /// WebView scroll offset을 chrome 전환 기준으로 줄인 event입니다.
        let webRootScroll: Signal<SessionWebRootScrollEvent>
        /// WebView navigation finish event입니다. 첫 finish는 새 Session의 peek 상태를 보여주기 위해 무시합니다.
        let browserNavigationFinished: Signal<Void>
        let bottomSheetDragEnded: Signal<SessionBottomSheetAction>
    }

    struct Output {
        /// Browser가 처음 load해야 하는 URL command입니다.
        let initialLoadURL: Signal<URL>
        /// Top Bar와 Bottom Sheet가 같은 chrome state를 읽도록 내보냅니다.
        let chromeState: Driver<SessionChromeState>
        /// ViewController가 처리해야 하는 화면 이동 의도입니다.
        let route: Signal<SessionRoute>
    }

    private let context: SessionLaunchContext
    private let chromePolicy: SessionChromePolicy

    init(
        context: SessionLaunchContext,
        chromePolicy: SessionChromePolicy = SessionChromePolicy()
    ) {
        self.context = context
        self.chromePolicy = chromePolicy
    }

    func transform(input: Input) -> Output {
        let initialLoadURL = input.viewDidLoad
            .compactMap { [initialURL = context.initialURL] in
                initialURL
            }

        let chromeState = chromeActions(from: input)
            .asObservable()
            .scan(SessionChromeState.newSession) { [chromePolicy] state, action in
                chromePolicy.nextState(from: state, action: action)
            }
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
