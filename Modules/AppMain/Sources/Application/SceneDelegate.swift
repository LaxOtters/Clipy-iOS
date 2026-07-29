//
//  SceneDelegate.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import UIKit

import FeatureSession

/// 앱 window를 만들고 현재 root navigation 흐름을 시작합니다.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private static let isSplashCrossDissolveEnabled = true

    var window: UIWindow?

    private var homeViewController: UIViewController?
    private var navigationController: AppMainNavigationController?
    private var splashStateMachine: AppSplashLifecycleStateMachine?
    private var splashViewController: AppSplashViewController?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = AppMainNavigationController()
        let homeComposer = AppMainHomeComposer { [weak navigationController] context in
            let sessionViewController = SessionFeature.makeViewController(context: context)
            navigationController?.pushViewController(sessionViewController, animated: true)
        }
        let homeViewController = homeComposer.makeViewController()

        if claimProcessSplashPresentation() {
            let splashViewController = AppSplashViewController()
            navigationController.setViewControllers([splashViewController], animated: false)
            splashStateMachine = AppSplashLifecycleStateMachine(
                isCrossDissolveEnabled: Self.isSplashCrossDissolveEnabled
            )
            self.splashViewController = splashViewController
        } else {
            navigationController.setViewControllers([homeViewController], animated: false)
        }

        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        self.homeViewController = homeViewController
        self.navigationController = navigationController
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard splashStateMachine != nil else {
            return
        }

        executeSplashCommand(
            handleSplashEvent(
                .becameActive(
                    isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                    isAnimationAvailable: splashViewController?.isAnimationAvailable == true
                )
            )
        )
    }

    func sceneWillResignActive(_ scene: UIScene) {
        guard splashStateMachine != nil else {
            return
        }

        executeSplashCommand(handleSplashEvent(.becameInactive))
    }

    private func claimProcessSplashPresentation() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            assertionFailure("AppDelegate must be available before connecting a scene.")
            return false
        }

        return appDelegate.claimSplashPresentation()
    }

    private func handleSplashEvent(_ event: AppSplashEvent) -> AppSplashCommand? {
        guard var splashStateMachine else {
            return nil
        }

        let command = splashStateMachine.handle(event)
        self.splashStateMachine = splashStateMachine
        return command
    }

    private func executeSplashCommand(_ command: AppSplashCommand?) {
        guard let command else {
            return
        }

        switch command {
        case .playAnimation:
            splashViewController?.startPlayback { [weak self] finished in
                guard let self else {
                    return
                }

                let isSceneActive = self.window?.windowScene?.activationState == .foregroundActive
                self.executeSplashCommand(
                    self.handleSplashEvent(
                        .playbackCompleted(
                            finished: finished,
                            isSceneActive: isSceneActive
                        )
                    )
                )
            }

        case .stopAnimation:
            splashViewController?.stopPlayback()

        case let .showHome(transition):
            showHome(transition: transition)
        }
    }

    private func showHome(transition: AppSplashTransition) {
        guard let homeViewController, let navigationController else {
            assertionFailure("Home presentation dependencies must be available before showing Home.")
            return
        }

        switch transition {
        case .none:
            navigationController.setViewControllers([homeViewController], animated: false)
            finishSplashPresentation()

        case .crossDissolve:
            UIView.transition(
                with: navigationController.view,
                duration: 0.25,
                options: [.transitionCrossDissolve, .beginFromCurrentState]
            ) {
                navigationController.setViewControllers([homeViewController], animated: false)
            } completion: { [weak self] _ in
                self?.finishSplashPresentation()
            }
        }
    }

    private func finishSplashPresentation() {
        splashViewController = nil
        splashStateMachine = nil
    }
}
