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

/// 상단 floating bar를 전체로 보여줄지, 접어서 보여줄지 나타냅니다.
enum SessionTopBarState: Equatable {
    case folded
    case unfolded
}

/// Session 진입 입력을 WebView load command와 화면 route로 바꿉니다.
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

        let route = input.homeTap
            .map { SessionRoute.home }

        return Output(
            initialLoadURL: initialLoadURL,
            route: route
        )
    }
}
