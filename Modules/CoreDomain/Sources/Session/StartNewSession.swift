//
//  StartNewSession.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

public struct StartNewSession {
    private let sessionRepository: any SessionRepository
    private let makeSessionID: () -> UUID
    private let now: () -> Date

    public init(
        sessionRepository: any SessionRepository,
        makeSessionID: @escaping () -> UUID = { UUID() },
        now: @escaping () -> Date = { Date() }
    ) {
        self.sessionRepository = sessionRepository
        self.makeSessionID = makeSessionID
        self.now = now
    }

    public func execute() async throws -> SessionSnapshot {
        let sessionID = makeSessionID()
        let timestamp = now()
        let session = Session(
            id: sessionID,
            status: .draft,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        let viewState = SessionViewState(
            sessionId: sessionID,
            bottomSheetState: .peek,
            lastOpenedAt: timestamp
        )
        let snapshot = SessionSnapshot(session: session, viewState: viewState)

        try await sessionRepository.save(snapshot)
        return snapshot
    }
}
