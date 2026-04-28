//
//  SceneDelegate.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import UIKit

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
        window.rootViewController = ClipyRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
