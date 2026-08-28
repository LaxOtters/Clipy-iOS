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
    /// AppMain이 세션 화면에 오버레이 요청자와 외부 URL 열기 동작을 주입하는 공개 경계입니다.
    @MainActor
    public struct Dependencies {
        public let overlayRequester: any ClipyOverlayRequesting
        public let openURL: @MainActor (URL) async -> Bool

        public init(
            overlayRequester: any ClipyOverlayRequesting,
            openURL: @escaping @MainActor (URL) async -> Bool
        ) {
            self.overlayRequester = overlayRequester
            self.openURL = openURL
        }
    }

    @MainActor
    public static func makeViewController(
        context: SessionLaunchContext,
        dependencies: Dependencies
    ) -> UIViewController {
        SessionViewController(
            viewModel: SessionViewModel(context: context),
            dependencies: dependencies
        )
    }
}
