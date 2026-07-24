//
//  CoreDataStartNewSessionWorkTests.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import CoreData
import XCTest

import CoreDomain
import CorePersistence

@testable import AppMain

final class CoreDataStartNewSessionWorkTests: XCTestCase {
    func test_retryingAfterStackInitializationFailure_retriesAndSavesSession() async throws {
        var stackFactoryCallCount = 0
        var initializedStack: ClipyCoreDataStack?
        let sut = CoreDataStartNewSessionWork {
            stackFactoryCallCount += 1

            if stackFactoryCallCount == 1 {
                throw StackInitializationError.failed
            }

            let stack = try ClipyCoreDataStack(storeType: NSInMemoryStoreType)
            initializedStack = stack
            return stack
        }

        do {
            _ = try await sut.execute()
            XCTFail("Expected the first stack initialization to fail.")
        } catch StackInitializationError.failed {
        }

        let sessionID = try await sut.execute()
        let repository = CoreDataSessionRepository(stack: try XCTUnwrap(initializedStack))
        let savedSnapshot = try await repository.loadSession(id: sessionID)

        XCTAssertEqual(stackFactoryCallCount, 2)
        XCTAssertEqual(savedSnapshot?.session.id, sessionID)
        XCTAssertEqual(savedSnapshot?.session.status, .draft)
    }
}

private enum StackInitializationError: Error {
    case failed
}
