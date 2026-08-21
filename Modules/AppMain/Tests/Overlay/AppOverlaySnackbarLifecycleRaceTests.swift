//
//  AppOverlaySnackbarLifecycleRaceTests.swift
//  Clipy
//
//  Created by 박민서 on 8/22/26.
//

import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlaySnackbarLifecycleRaceTests: XCTestCase {
    func test_actionReenqueueingExactTuple_keepsExistingFIFOOrder_afterUnmountAndAction() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var reentrantResult: ClipySnackbar.EnqueueResult?

        func makeFirstRequest() -> ClipySnackbar.Request {
            .init(message: "A", action: .init(title: "Run") {
                host.recordEvent("action:A")
                reentrantResult = coordinator.enqueueSnackbar(makeFirstRequest())
            })
        }

        XCTAssertEqual(coordinator.enqueueSnackbar(makeFirstRequest()), .accepted)
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "B")), .accepted)

        host.snackbarCallbacks[0].onAction?()
        XCTAssertNil(reentrantResult)

        host.completeSnackbarUnmount(at: 0)

        XCTAssertEqual(reentrantResult, .accepted)
        XCTAssertEqual(host.snackbarMessages, ["A", "B"])
        XCTAssertEqual(
            host.events,
            [
                "snackbarMounted:A",
                "snackbarUnmountRequested",
                "snackbarUnmountCompleted",
                "action:A",
                "snackbarMounted:B"
            ]
        )

        host.snackbarCallbacks[1].onDismiss()
        host.completeSnackbarUnmount(at: 1)

        XCTAssertEqual(host.snackbarMessages, ["A", "B", "A"])
    }

    func test_tappedAction_hostDetach_clearsFIFOAndInvokesActionOnce_afterForcedRemoval() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)
        var actionCount = 0
        var reentrantResult: ClipySnackbar.EnqueueResult?
        weak var actionSentinel: LifetimeSentinel?
        weak var queuedSentinel: LifetimeSentinel?

        do {
            let actionCapture = LifetimeSentinel()
            let queuedCapture = LifetimeSentinel()
            actionSentinel = actionCapture
            queuedSentinel = queuedCapture
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Run") { [actionCapture] in
                        _ = actionCapture
                        actionCount += 1
                        reentrantResult = coordinator.enqueueSnackbar(.init(message: "C"))
                    })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Run") { [queuedCapture] in
                        _ = queuedCapture
                    })
                ),
                .accepted
            )
        }

        host.snackbarCallbacks[0].onAction?()
        coordinator.hostDidDetach()

        XCTAssertNotNil(actionSentinel)
        XCTAssertNil(queuedSentinel)
        XCTAssertEqual(actionCount, 0)

        host.completeSnackbarUnmount(at: 1)

        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(reentrantResult, .unavailable(.hostUnavailable))
        XCTAssertNil(actionSentinel)
        XCTAssertEqual(host.snackbarMessages, ["A"])

        host.completeSnackbarUnmount(at: 0)
        host.snackbarCallbacks[0].onAction?()
        scheduler.tasks[0].fireEvenIfCancelled()

        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(host.snackbarMessages, ["A"])
    }

    func test_tappedAction_shutdown_clearsFIFOAndInvokesActionOnce_afterForcedRemoval() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)
        var actionCount = 0
        var reentrantResult: ClipySnackbar.EnqueueResult?
        weak var actionSentinel: LifetimeSentinel?
        weak var queuedSentinel: LifetimeSentinel?

        do {
            let actionCapture = LifetimeSentinel()
            let queuedCapture = LifetimeSentinel()
            actionSentinel = actionCapture
            queuedSentinel = queuedCapture
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Run") { [actionCapture] in
                        _ = actionCapture
                        actionCount += 1
                        reentrantResult = coordinator.enqueueSnackbar(.init(message: "C"))
                    })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Run") { [queuedCapture] in
                        _ = queuedCapture
                    })
                ),
                .accepted
            )
        }

        host.snackbarCallbacks[0].onAction?()
        coordinator.shutdown()

        XCTAssertNotNil(actionSentinel)
        XCTAssertNil(queuedSentinel)
        XCTAssertEqual(actionCount, 0)

        host.completeSnackbarUnmount(at: 1)

        XCTAssertEqual(actionCount, 1)
        guard case .unavailable = reentrantResult else {
            return XCTFail("A shutdown coordinator must reject requests enqueued by the selected action.")
        }
        XCTAssertNil(actionSentinel)
        XCTAssertEqual(host.snackbarMessages, ["A"])

        host.completeSnackbarUnmount(at: 0)
        host.snackbarCallbacks[0].onAction?()
        scheduler.tasks[0].fireEvenIfCancelled()

        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(host.snackbarMessages, ["A"])
    }
}
