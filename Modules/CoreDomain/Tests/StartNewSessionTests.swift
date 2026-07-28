//
//  StartNewSessionTests.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import XCTest

import CoreDomain

final class StartNewSessionTests: XCTestCase {
    func test_startingNewSession_createsDraftSession_readyForBrowsing() async throws {
        let repository = SessionRepositorySpy()
        let sessionId = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let operation = StartNewSession(
            sessionRepository: repository,
            makeSessionID: { sessionId },
            now: { now }
        )

        let snapshot = try await operation.execute()

        XCTAssertEqual(snapshot.session.id, sessionId)
        XCTAssertNil(snapshot.session.name)
        XCTAssertEqual(snapshot.session.status, SessionStatus.draft)
        XCTAssertEqual(snapshot.session.createdAt, now)
        XCTAssertEqual(snapshot.session.updatedAt, now)
        XCTAssertNil(snapshot.session.closedAt)
        XCTAssertNil(snapshot.session.abandonedAt)
        XCTAssertTrue(snapshot.session.items.isEmpty)
        XCTAssertTrue(snapshot.session.decisions.isEmpty)
        XCTAssertEqual(snapshot.viewState?.sessionId, sessionId)
        XCTAssertNil(snapshot.viewState?.lastWebUrl)
        XCTAssertEqual(snapshot.viewState?.bottomSheetState, .peek)
        XCTAssertEqual(snapshot.viewState?.lastOpenedAt, now)
        XCTAssertEqual(snapshot.viewState?.resolvedUIState(decisionCount: 0), .browsing)
        let savedSnapshots = await repository.savedSnapshots()
        let saveCount = await repository.saveCount()
        XCTAssertEqual(savedSnapshots, [snapshot])
        XCTAssertEqual(saveCount, 1)
    }

    func test_startingNewSession_waitsForSave_beforeReturningSnapshot() async throws {
        let repository = BlockingSessionRepository()
        let operation = StartNewSession(sessionRepository: repository)
        let completion = ExecutionCompletion()

        let task = Task {
            do {
                let snapshot = try await operation.execute()
                await completion.recordSuccess(snapshot)
            } catch {
                await completion.recordFailure(error)
            }
        }

        await repository.waitUntilSaveStarts()

        let hasCompletedBeforeSaveFinishes = await completion.hasCompleted()
        let saveCountBeforeSaveFinishes = await repository.saveCount()
        XCTAssertFalse(hasCompletedBeforeSaveFinishes)
        XCTAssertEqual(saveCountBeforeSaveFinishes, 1)

        await repository.finishSave()
        await task.value

        let hasSucceeded = await completion.hasSucceeded()
        let returnedSnapshot = await completion.successfulSnapshot()
        let savedSnapshots = await repository.savedSnapshots()
        XCTAssertTrue(hasSucceeded)
        XCTAssertEqual(savedSnapshots.count, 1)
        XCTAssertEqual(returnedSnapshot, savedSnapshots.first)
    }

    func test_startingNewSession_propagatesSaveFailure_withoutSuccessResult() async {
        let repository = FailingSessionRepository()
        let operation = StartNewSession(sessionRepository: repository)

        do {
            _ = try await operation.execute()
            XCTFail("저장 실패는 성공 결과로 바뀌면 안 됩니다.")
        } catch let error as TestRepositoryError {
            XCTAssertEqual(error, .saveFailed)
        } catch {
            XCTFail("원래 저장 오류가 전달되어야 합니다: \(error)")
        }

        let saveCount = await repository.saveCount()
        XCTAssertEqual(saveCount, 1)
    }

    func test_startingNewSession_samplesNewIdentityAndTime_oncePerExecution() async throws {
        let repository = SessionRepositorySpy()
        let identifiers = IdentifierProvider([
            UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000203")!
        ])
        let dates = DateProvider([
            Date(timeIntervalSince1970: 1_800_000_001),
            Date(timeIntervalSince1970: 1_800_000_002)
        ])
        let operation = StartNewSession(
            sessionRepository: repository,
            makeSessionID: identifiers.next,
            now: dates.next
        )

        XCTAssertEqual(identifiers.callCount, 0)
        XCTAssertEqual(dates.callCount, 0)

        let first = try await operation.execute()

        XCTAssertEqual(identifiers.callCount, 1)
        XCTAssertEqual(dates.callCount, 1)
        let firstSaveCount = await repository.saveCount()
        XCTAssertEqual(firstSaveCount, 1)

        let second = try await operation.execute()

        XCTAssertNotEqual(first.session.id, second.session.id)
        XCTAssertNotEqual(first.session.createdAt, second.session.createdAt)
        XCTAssertEqual(first.session.createdAt, first.session.updatedAt)
        XCTAssertEqual(first.session.createdAt, first.viewState?.lastOpenedAt)
        XCTAssertEqual(second.session.createdAt, second.session.updatedAt)
        XCTAssertEqual(second.session.createdAt, second.viewState?.lastOpenedAt)
        XCTAssertEqual(identifiers.callCount, 2)
        XCTAssertEqual(dates.callCount, 2)
        let savedSnapshots = await repository.savedSnapshots()
        XCTAssertEqual(savedSnapshots, [first, second])
        let saveCount = await repository.saveCount()
        XCTAssertEqual(saveCount, 2)
    }
}

private actor SessionRepositorySpy: SessionRepository {
    private var snapshots: [SessionSnapshot] = []

    func save(_ snapshot: SessionSnapshot) async throws {
        snapshots.append(snapshot)
    }

    func loadSession(id: UUID) async throws -> SessionSnapshot? {
        nil
    }

    func savedSnapshots() -> [SessionSnapshot] {
        snapshots
    }

    func saveCount() -> Int {
        snapshots.count
    }
}

private actor BlockingSessionRepository: SessionRepository {
    private var didStartSave = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var finishSaveContinuation: CheckedContinuation<Void, Never>?
    private var saves = 0
    private var snapshots: [SessionSnapshot] = []

    func save(_ snapshot: SessionSnapshot) async throws {
        saves += 1
        snapshots.append(snapshot)
        didStartSave = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()

        await withCheckedContinuation { continuation in
            finishSaveContinuation = continuation
        }
    }

    func loadSession(id: UUID) async throws -> SessionSnapshot? {
        nil
    }

    func waitUntilSaveStarts() async {
        guard !didStartSave else { return }

        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func finishSave() {
        finishSaveContinuation?.resume()
        finishSaveContinuation = nil
    }

    func saveCount() -> Int {
        saves
    }

    func savedSnapshots() -> [SessionSnapshot] {
        snapshots
    }
}

private actor FailingSessionRepository: SessionRepository {
    private var saves = 0

    func save(_ snapshot: SessionSnapshot) async throws {
        saves += 1
        throw TestRepositoryError.saveFailed
    }

    func loadSession(id: UUID) async throws -> SessionSnapshot? {
        nil
    }

    func saveCount() -> Int {
        saves
    }
}

private actor ExecutionCompletion {
    private var result: Result<SessionSnapshot, Error>?

    func recordSuccess(_ snapshot: SessionSnapshot) {
        result = .success(snapshot)
    }

    func recordFailure(_ error: Error) {
        result = .failure(error)
    }

    func hasCompleted() -> Bool {
        result != nil
    }

    func hasSucceeded() -> Bool {
        guard case .success = result else { return false }
        return true
    }

    func successfulSnapshot() -> SessionSnapshot? {
        guard case let .success(snapshot) = result else { return nil }
        return snapshot
    }
}

private enum TestRepositoryError: Error, Equatable {
    case saveFailed
}

private final class IdentifierProvider {
    private var identifiers: [UUID]
    private(set) var callCount = 0

    init(_ identifiers: [UUID]) {
        self.identifiers = identifiers
    }

    func next() -> UUID {
        callCount += 1
        return identifiers.removeFirst()
    }
}

private final class DateProvider {
    private var dates: [Date]
    private(set) var callCount = 0

    init(_ dates: [Date]) {
        self.dates = dates
    }

    func next() -> Date {
        callCount += 1
        return dates.removeFirst()
    }
}
