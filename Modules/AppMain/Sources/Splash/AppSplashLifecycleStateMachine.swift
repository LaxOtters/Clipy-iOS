//
//  AppSplashLifecycleStateMachine.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

enum AppSplashTransition: Equatable {
    case none
    case crossDissolve
}

enum AppSplashCommand: Equatable {
    case playAnimation
    case stopAnimation
    case showHome(transition: AppSplashTransition)
}

enum AppSplashEvent {
    case becameActive(isReduceMotionEnabled: Bool, isAnimationAvailable: Bool)
    case playbackCompleted(finished: Bool, isSceneActive: Bool)
    case becameInactive
}

struct AppSplashLifecycleStateMachine {
    private enum State {
        case idle
        case playing
        case interrupted
        case homeShown
    }

    private let isCrossDissolveEnabled: Bool
    private var state: State = .idle

    init(isCrossDissolveEnabled: Bool) {
        self.isCrossDissolveEnabled = isCrossDissolveEnabled
    }

    mutating func handle(_ event: AppSplashEvent) -> AppSplashCommand? {
        switch (state, event) {
        case let (.idle, .becameActive(isReduceMotionEnabled, isAnimationAvailable)):
            guard !isReduceMotionEnabled, isAnimationAvailable else {
                state = .homeShown
                return .showHome(transition: .none)
            }

            state = .playing
            return .playAnimation

        case (.playing, .becameInactive):
            state = .interrupted
            return .stopAnimation

        case let (.playing, .playbackCompleted(_, isSceneActive)) where !isSceneActive:
            state = .interrupted
            return nil

        case let (.playing, .playbackCompleted(finished, isSceneActive)) where isSceneActive:
            state = .homeShown
            let transition: AppSplashTransition = finished && isCrossDissolveEnabled
                ? .crossDissolve
                : .none
            return .showHome(transition: transition)

        case (.interrupted, .becameActive):
            state = .homeShown
            return .showHome(transition: .none)

        default:
            return nil
        }
    }
}
