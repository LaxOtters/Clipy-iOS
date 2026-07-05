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

/// 새 Session의 첫 렌더링에 필요한 상단 chrome 상태입니다.
struct SessionInitialChromeState: Equatable {
    let topBarState: SessionTopBarState

    static let newSession = SessionInitialChromeState(
        topBarState: .unfolded
    )
}

/// Session 진입 event와 home tap을 초기 URL load, 초기 chrome 상태, route로 바꿉니다.
final class SessionViewModel {
    struct Input {
        /// 화면 최초 진입 시 초기 URL load를 시작하는 lifecycle event입니다.
        let viewDidLoad: Signal<Void>
        /// Home button tap으로 들어오는 화면 종료 event입니다.
        let homeTap: Signal<Void>
    }

    struct Output {
        /// Browser가 처음 load해야 하는 URL command입니다.
        let initialLoadURL: Signal<URL>
        /// 새 Session 진입 직후 Top Bar가 읽는 초기 chrome 상태입니다.
        let initialChromeState: Signal<SessionInitialChromeState>
        /// ViewController가 처리해야 하는 화면 이동 의도입니다.
        let route: Signal<SessionRoute>
    }

    private let context: SessionLaunchContext

    init(context: SessionLaunchContext) {
        self.context = context
    }

    func transform(input: Input) -> Output {
        let initialLoadURL = input.viewDidLoad
            .compactMap { [initialURL = context.initialURL] in
                initialURL
            }

        let initialChromeState = input.viewDidLoad
            .map { SessionInitialChromeState.newSession }

        let route = input.homeTap
            .map { SessionRoute.home }

        return Output(
            initialLoadURL: initialLoadURL,
            initialChromeState: initialChromeState,
            route: route
        )
    }
}
