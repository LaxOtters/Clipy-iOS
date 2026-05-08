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
