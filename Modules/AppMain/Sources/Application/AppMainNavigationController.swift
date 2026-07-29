//
//  AppMainNavigationController.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

import UIKit

final class AppMainNavigationController: UINavigationController {
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    override var childForHomeIndicatorAutoHidden: UIViewController? {
        nil
    }
}
