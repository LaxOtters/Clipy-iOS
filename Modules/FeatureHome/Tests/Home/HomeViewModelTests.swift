//
//  HomeViewModelTests.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import XCTest

import RxCocoa
import RxRelay
import RxSwift

@testable import FeatureHome

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func test_startingSession_disablesCTAAndIgnoresDuplicateTap_whileSaveIsPending() async {
        let startRequested = expectation(description: "start requested")
        let pendingStart = PendingStart {
            startRequested.fulfill()
        }
        let beginComparisonTap = PublishRelay<Void>()
        let sut = HomeViewModel(startNewSession: {
            try await pendingStart.execute()
        })
        let output = sut.transform(
            input: .init(beginComparisonTap: beginComparisonTap.asSignal())
        )
        var enabledStates: [Bool] = []

        output.isStartEnabled
            .drive(onNext: { enabledStates.append($0) })
            .disposed(by: disposeBag)

        beginComparisonTap.accept(())
        beginComparisonTap.accept(())

        await fulfillment(of: [startRequested], timeout: 1)

        XCTAssertEqual(enabledStates, [true, false])
        XCTAssertEqual(pendingStart.callCount, 1)

        pendingStart.resume(with: .failure(TestError.failed))
    }

    func test_startingSession_routesOnce_afterSavedSessionIsReturned() async {
        let savedSessionID = UUID()
        let routed = expectation(description: "saved session route")
        let beginComparisonTap = PublishRelay<Void>()
        let sut = HomeViewModel(startNewSession: { savedSessionID })
        let output = sut.transform(
            input: .init(beginComparisonTap: beginComparisonTap.asSignal())
        )
        var enabledStates: [Bool] = []
        var routes: [HomeFeatureRoute] = []

        output.isStartEnabled
            .drive(onNext: { enabledStates.append($0) })
            .disposed(by: disposeBag)
        output.route
            .emit(onNext: { route in
                routes.append(route)
                routed.fulfill()
            })
            .disposed(by: disposeBag)

        beginComparisonTap.accept(())

        await fulfillment(of: [routed], timeout: 1)

        XCTAssertEqual(routes, [.session(savedSessionID)])
        XCTAssertEqual(enabledStates, [true, false, true])
    }

    func test_startingSession_showsFailureAlertAndReenablesCTA_withoutRouting() async {
        let failureAlert = expectation(description: "failure alert")
        let beginComparisonTap = PublishRelay<Void>()
        let sut = HomeViewModel(startNewSession: { throw TestError.failed })
        let output = sut.transform(
            input: .init(beginComparisonTap: beginComparisonTap.asSignal())
        )
        var enabledStates: [Bool] = []
        var routes: [HomeFeatureRoute] = []

        output.isStartEnabled
            .drive(onNext: { enabledStates.append($0) })
            .disposed(by: disposeBag)
        output.route
            .emit(onNext: { routes.append($0) })
            .disposed(by: disposeBag)
        output.failureAlert
            .emit(onNext: { failureAlert.fulfill() })
            .disposed(by: disposeBag)

        beginComparisonTap.accept(())

        await fulfillment(of: [failureAlert], timeout: 1)

        XCTAssertEqual(enabledStates, [true, false, true])
        XCTAssertTrue(routes.isEmpty)
    }

    func test_retryingAfterFailure_startsNewSessionAgain() async {
        let savedSessionID = UUID()
        let routeExpectation = expectation(description: "retry route")
        let start = ResultQueueStart(results: [.failure(TestError.failed), .success(savedSessionID)])
        let beginComparisonTap = PublishRelay<Void>()
        let sut = HomeViewModel(startNewSession: {
            try start.execute()
        })
        let output = sut.transform(
            input: .init(beginComparisonTap: beginComparisonTap.asSignal())
        )
        let failureAlert = expectation(description: "first failure")
        var routes: [HomeFeatureRoute] = []

        output.failureAlert
            .emit(onNext: { failureAlert.fulfill() })
            .disposed(by: disposeBag)
        output.route
            .emit(onNext: { route in
                routes.append(route)
                routeExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        beginComparisonTap.accept(())
        await fulfillment(of: [failureAlert], timeout: 1)

        beginComparisonTap.accept(())
        await fulfillment(of: [routeExpectation], timeout: 1)

        XCTAssertEqual(start.callCount, 2)
        XCTAssertEqual(routes, [.session(savedSessionID)])
    }
}

private enum TestError: Error {
    case failed
}

private final class PendingStart {
    var callCount = 0
    private let onStart: () -> Void
    private var continuation: CheckedContinuation<UUID, Error>?

    init(onStart: @escaping () -> Void) {
        self.onStart = onStart
    }

    func execute() async throws -> UUID {
        callCount += 1
        onStart()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with result: Result<UUID, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

private final class ResultQueueStart {
    var callCount = 0
    private var results: [Result<UUID, Error>]

    init(results: [Result<UUID, Error>]) {
        self.results = results
    }

    func execute() throws -> UUID {
        callCount += 1
        return try results.removeFirst().get()
    }
}
