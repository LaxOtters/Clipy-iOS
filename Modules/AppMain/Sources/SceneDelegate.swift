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
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        let homeComposer = AppMainHomeComposer { [weak navigationController] context in
            let sessionViewController = SessionFeature.makeViewController(context: context)
            navigationController?.pushViewController(sessionViewController, animated: true)
        }
        navigationController.setViewControllers([homeComposer.makeViewController()], animated: false)
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
