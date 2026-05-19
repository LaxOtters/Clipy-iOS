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
    case home
}

/// Session 진입 입력을 WebView load command와 화면 route로 바꿉니다.
final class SessionViewModel {
    struct Input {
        let viewDidLoad: Signal<Void>
        let homeTap: Signal<Void>
    }

    struct Output {
        let initialLoadURL: Signal<URL>
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
