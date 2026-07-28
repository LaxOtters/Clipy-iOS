//
//  CoreDataStartNewSessionWork.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

import CoreDomain
import CorePersistence

final class CoreDataStartNewSessionWork {
    private let makeCoreDataStack: () throws -> ClipyCoreDataStack
    private var operation: StartNewSession?

    init(makeCoreDataStack: @escaping () throws -> ClipyCoreDataStack) {
        self.makeCoreDataStack = makeCoreDataStack
    }

    func execute() async throws -> UUID {
        if let operation {
            return try await operation.execute().session.id
        }

        let repository = CoreDataSessionRepository(stack: try makeCoreDataStack())
        let operation = StartNewSession(sessionRepository: repository)
        self.operation = operation
        return try await operation.execute().session.id
    }
}
