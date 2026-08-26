//
//  SessionFeature.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit

import CoreDesignSystem

/// AppMain이 Session 화면을 열 때 사용하는 FeatureSession의 공개 진입점입니다.
public enum SessionFeature {
    @MainActor
    public static func makeViewController(
        context: SessionLaunchContext,
        overlayRequester: any ClipyOverlayRequesting
    ) -> UIViewController {
        SessionViewController(
            viewModel: SessionViewModel(context: context),
            overlayRequester: overlayRequester
        )
    }
}
