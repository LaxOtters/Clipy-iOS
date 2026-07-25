//
//  AppSplashLifecycleStateMachineTests.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

import XCTest

@testable import AppMain

final class AppSplashLifecycleStateMachineTests: XCTestCase {
    func test_becomingActiveWithAnimationAvailable_startsPlayback_forColdLaunch() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )

        let command = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        XCTAssertEqual(command, .playAnimation)
    }

    func test_completingPlayback_routesHomeOnce_withConfiguredTransition() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )
        _ = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        let firstCommand = stateMachine.handle(
            .playbackCompleted(finished: true, isSceneActive: true)
        )
        let duplicateCommand = stateMachine.handle(
            .playbackCompleted(finished: true, isSceneActive: true)
        )

        XCTAssertEqual(firstCommand, .showHome(transition: .crossDissolve))
        XCTAssertNil(duplicateCommand)
    }

    func test_cancellingPlaybackWhileActive_routesHomeWithoutDissolve_forPlaybackFallback() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )
        _ = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        let command = stateMachine.handle(
            .playbackCompleted(finished: false, isSceneActive: true)
        )

        XCTAssertEqual(command, .showHome(transition: .none))
    }

    func test_completingPlaybackWithTransitionDisabled_keepsPlaybackAndRoutesWithoutDissolve() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: false
        )

        let startCommand = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )
        let completionCommand = stateMachine.handle(
            .playbackCompleted(finished: true, isSceneActive: true)
        )

        XCTAssertEqual(startCommand, .playAnimation)
        XCTAssertEqual(completionCommand, .showHome(transition: .none))
    }

    func test_becomingActiveWithReduceMotion_routesHomeWithoutPlaybackOrDissolve() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )

        let command = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: true, isAnimationAvailable: true)
        )

        XCTAssertEqual(command, .showHome(transition: .none))
    }

    func test_becomingActiveWithoutAnimation_routesHomeWithoutDissolve_forResourceFallback() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )

        let command = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: false)
        )

        XCTAssertEqual(command, .showHome(transition: .none))
    }

    func test_becomingInactive_ignoresCompletionAndRoutesOnNextActive_once() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )
        _ = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        let inactiveCommand = stateMachine.handle(.becameInactive)
        let completionCommand = stateMachine.handle(
            .playbackCompleted(finished: true, isSceneActive: false)
        )
        let activeCommand = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )
        let repeatedActiveCommand = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        XCTAssertEqual(inactiveCommand, .stopAnimation)
        XCTAssertNil(completionCommand)
        XCTAssertEqual(activeCommand, .showHome(transition: .none))
        XCTAssertNil(repeatedActiveCommand)
    }

    func test_completingInInactiveScene_waitsForNextActive_withoutRequiringInactiveEvent() {
        var stateMachine = AppSplashLifecycleStateMachine(
            isCrossDissolveEnabled: true
        )
        _ = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        let completionCommand = stateMachine.handle(
            .playbackCompleted(finished: true, isSceneActive: false)
        )
        let activeCommand = stateMachine.handle(
            .becameActive(isReduceMotionEnabled: false, isAnimationAvailable: true)
        )

        XCTAssertNil(completionCommand)
        XCTAssertEqual(activeCommand, .showHome(transition: .none))
    }
}
