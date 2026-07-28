//
//  AppMainHomeComposer.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import CorePersistence
import FeatureHome
import FeatureSession

/// CoreData의 새 Session 작업을 Home에 주입하고 FeatureHome route를 Session 화면으로 바꿉니다.
final class AppMainHomeComposer {
    typealias StartNewSessionWork = () async throws -> UUID
    typealias SessionRouteHandler = (SessionLaunchContext) -> Void

    private let startNewSession: StartNewSessionWork
    private let onSessionRoute: SessionRouteHandler

    convenience init(onSessionRoute: @escaping SessionRouteHandler) {
        self.init(
            makeCoreDataStack: { try ClipyCoreDataStack() },
            onSessionRoute: onSessionRoute
        )
    }

    init(
        makeCoreDataStack: @escaping () throws -> ClipyCoreDataStack,
        onSessionRoute: @escaping SessionRouteHandler
    ) {
        let work = CoreDataStartNewSessionWork(makeCoreDataStack: makeCoreDataStack)
        self.startNewSession = {
            try await work.execute()
        }
        self.onSessionRoute = onSessionRoute
    }

    func makeViewController() -> UIViewController {
        HomeFeature.makeViewController(
            dependencies: HomeFeatureDependencies(
                startNewSession: startNewSession,
                onRoute: { [onSessionRoute] route in
                    switch route {
                    case let .session(sessionID):
                        onSessionRoute(Self.makeSessionLaunchContext(sessionID: sessionID))
                    }
                }
            )
        )
    }

    static func makeSessionLaunchContext(sessionID: UUID) -> SessionLaunchContext {
        SessionLaunchContext(
            sessionId: sessionID,
            initialURL: nil
        )
    }
}
