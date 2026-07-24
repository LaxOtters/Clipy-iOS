//
//  HomeFeature.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

/// AppMain이 First Use Home 화면을 조립할 때 사용하는 공개 진입점입니다.
public enum HomeFeature {
    public static func makeViewController(
        dependencies: HomeFeatureDependencies
    ) -> UIViewController {
        HomeViewController(
            viewModel: HomeViewModel(startNewSession: dependencies.startNewSession),
            onRoute: dependencies.onRoute
        )
    }
}
