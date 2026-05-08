//
//  SessionLaunchContext.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

public struct SessionLaunchContext: Equatable {
    public let sessionId: UUID
    public let initialURL: URL?

    public init(sessionId: UUID, initialURL: URL? = nil) {
        self.sessionId = sessionId
        self.initialURL = initialURL
    }
}
