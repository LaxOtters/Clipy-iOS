//
//  HomeFeatureDependencies.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

/// Home이 새 세션 시작 결과와 화면 이동을 AppMain에 전달하는 좁은 경계입니다.
public struct HomeFeatureDependencies {
    public let startNewSession: () async throws -> UUID
    public let onRoute: (HomeFeatureRoute) -> Void

    public init(
        startNewSession: @escaping () async throws -> UUID,
        onRoute: @escaping (HomeFeatureRoute) -> Void
    ) {
        self.startNewSession = startNewSession
        self.onRoute = onRoute
    }
}
