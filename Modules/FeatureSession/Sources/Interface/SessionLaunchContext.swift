//
//  SessionLaunchContext.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

/// Session 화면을 열 때 이미 결정된 session id와 초기 URL을 전달합니다.
public struct SessionLaunchContext: Equatable {
    public let sessionId: UUID
    public let initialURL: URL?

    public init(sessionId: UUID, initialURL: URL? = nil) {
        self.sessionId = sessionId
        self.initialURL = initialURL
    }
}
