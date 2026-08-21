//
//  AppOverlaySnackbarCoordinatorTests.swift
//  Clipy
//
//  Created by 박민서 on 8/22/26.
//

import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlaySnackbarCoordinatorTests: XCTestCase {
    func test_occupiedHost_keepsIncumbentOutsideTapAuthority_withTwoCoordinators() {
        let host = OverlayHostSpy()
        let firstScheduler = OverlaySchedulerSpy()
        let secondScheduler = OverlaySchedulerSpy()
        let firstCoordinator = makeOverlayCoordinator(host: host, scheduler: firstScheduler)
        let secondCoordinator = makeOverlayCoordinator(host: host, scheduler: secondScheduler)

        XCTAssertEqual(firstCoordinator.enqueueSnackbar(.init(message: "First")), .accepted)
        XCTAssertEqual(secondCoordinator.enqueueSnackbar(.init(message: "Second")), .accepted)

        XCTAssertEqual(host.snackbarMessages, ["First"])
        XCTAssertEqual(host.mountedSnackbarCount, 1)
        XCTAssertEqual(firstScheduler.tasks.count, 1)
        XCTAssertTrue(secondScheduler.tasks.isEmpty)

        host.outsideTapHandler?()

        XCTAssertEqual(host.snackbarUnmountAnimations, [true])
        XCTAssertEqual(host.mountedSnackbarCount, 0)
        XCTAssertNil(host.outsideTapHandler)
    }

    func test_snackbarQueue_deduplicatesExactTupleAndAdvancesFIFO() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        var firstActionCount = 0
        var duplicateActionCount = 0
        var secondActionCount = 0
        var differentTitleActionCount = 0

        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved", action: .init(title: "Undo") { firstActionCount += 1 })
            ),
            .accepted
        )
        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved", action: .init(title: "Undo") { duplicateActionCount += 1 })
            ),
            .duplicateDropped
        )
        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved ", action: .init(title: "Undo") { secondActionCount += 1 })
            ),
            .accepted
        )
        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved", action: .init(title: "Retry") { differentTitleActionCount += 1 })
            ),
            .accepted
        )

        host.snackbarCallbacks[0].onAction?()

        XCTAssertEqual(firstActionCount, 1)
        XCTAssertEqual(duplicateActionCount, 0)
        XCTAssertEqual(host.snackbarCallbacks.count, 2)

        host.snackbarCallbacks[1].onAction?()
        XCTAssertEqual(secondActionCount, 1)
        XCTAssertEqual(host.snackbarCallbacks.count, 3)

        host.snackbarCallbacks[2].onAction?()
        XCTAssertEqual(differentTitleActionCount, 1)
    }

    func test_snackbarQueue_keepsCanonicallyEquivalentAuthoredText_asDistinctFIFORequests() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)

        XCTAssertEqual(
            coordinator.enqueueSnackbar(.init(message: "\u{00E9}")),
            .accepted
        )
        XCTAssertEqual(
            coordinator.enqueueSnackbar(.init(message: "e\u{0301}")),
            .accepted
        )

        host.snackbarCallbacks[0].onDismiss()

        XCTAssertEqual(host.snackbarCallbacks.count, 2)
    }

    func test_droppedAndUnavailableSnackbars_doNotRetainActionCaptures() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        weak var duplicateSentinel: LifetimeSentinel?
        weak var unavailableSentinel: LifetimeSentinel?

        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved", action: .init(title: "Undo") {})
            ),
            .accepted
        )
        do {
            let sentinel = LifetimeSentinel()
            duplicateSentinel = sentinel
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "Saved", action: .init(title: "Undo") { [sentinel] in _ = sentinel })
                ),
                .duplicateDropped
            )
        }
        XCTAssertNil(duplicateSentinel)

        coordinator.sceneWillResignActive()
        do {
            let sentinel = LifetimeSentinel()
            unavailableSentinel = sentinel
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "Offline", action: .init(title: "Retry") { [sentinel] in _ = sentinel })
                ),
                .unavailable(.sceneInactive)
            )
        }
        XCTAssertNil(unavailableSentinel)
    }

    func test_snackbarActionAndLateTimer_invokeAdmittedActionOnlyOnce() {
        let host = OverlayHostSpy()
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)
        var actionCount = 0

        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "Saved", action: .init(title: "Undo") { actionCount += 1 })
            ),
            .accepted
        )
        XCTAssertEqual(scheduler.intervals, [2])
        let timer = scheduler.tasks[0]

        host.snackbarCallbacks[0].onAction?()
        timer.fireEvenIfCancelled()
        host.snackbarCallbacks[0].onAction?()

        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(host.mountedSnackbarCount, 0)
    }

    func test_enqueueDuringSnackbarDismissal_waitsForMatchingExitCompletion() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)

        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "A", action: .init(title: "Next") {
                    XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "C")), .accepted)
                })
            ),
            .accepted
        )
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "B")), .accepted)

        host.snackbarCallbacks[0].onAction?()

        XCTAssertEqual(host.snackbarCallbacks.count, 1)
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "A", action: .init(title: "Next") {})), .duplicateDropped)

        host.completeSnackbarUnmount(at: 0)

        XCTAssertEqual(host.snackbarCallbacks.count, 2)
    }

    func test_sceneInactivity_clearsVisibleAndQueuedSnackbars_withoutReplay() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        weak var visibleSentinel: LifetimeSentinel?
        weak var queuedSentinel: LifetimeSentinel?

        do {
            let visible = LifetimeSentinel()
            let queued = LifetimeSentinel()
            visibleSentinel = visible
            queuedSentinel = queued
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Run") { [visible] in _ = visible })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Run") { [queued] in _ = queued })
                ),
                .accepted
            )
        }

        coordinator.sceneWillResignActive()
        host.completeSnackbarUnmount(at: 0)

        XCTAssertNil(visibleSentinel)
        XCTAssertNil(queuedSentinel)
        XCTAssertEqual(host.snackbarCallbacks.count, 1)
        XCTAssertEqual(host.mountedSnackbarCount, 0)

        coordinator.sceneDidBecomeActive()

        XCTAssertEqual(host.snackbarCallbacks.count, 1)
        XCTAssertEqual(host.mountedSnackbarCount, 0)
    }
}

extension AppOverlaySnackbarCoordinatorTests {
    func test_lateSnackbarEntryCompletion_doesNotScheduleTimer_afterDismissalStarts() {
        let host = OverlayHostSpy(defersSnackbarMount: true, defersSnackbarUnmount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)

        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "A")), .accepted)
        host.snackbarCallbacks[0].onDismiss()

        host.completeSnackbarMount(at: 0, didDisplay: true)

        XCTAssertTrue(scheduler.tasks.isEmpty)

        host.completeSnackbarUnmount(at: 0)
    }

    func test_snackbarTimer_startsOnlyAfterSuccessfulEntryCompletion() {
        let host = OverlayHostSpy(defersSnackbarMount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)

        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "A")), .accepted)
        XCTAssertTrue(scheduler.tasks.isEmpty)

        host.completeSnackbarMount(at: 0, didDisplay: true)

        XCTAssertEqual(scheduler.intervals, [2])
    }

    func test_snackbarDisplayFailure_clearsQueueAndIgnoresLateEntryCompletion() {
        let host = OverlayHostSpy(defersSnackbarMount: true, defersSnackbarUnmount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)
        weak var visibleSentinel: LifetimeSentinel?
        weak var queuedSentinel: LifetimeSentinel?

        do {
            let visible = LifetimeSentinel()
            let queued = LifetimeSentinel()
            visibleSentinel = visible
            queuedSentinel = queued
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Run") { [visible] in _ = visible })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Run") { [queued] in _ = queued })
                ),
                .accepted
            )
        }

        host.completeSnackbarMount(at: 0, didDisplay: false)

        XCTAssertEqual(
            coordinator.enqueueSnackbar(.init(message: "A", action: .init(title: "Run") {})),
            .duplicateDropped
        )
        XCTAssertEqual(
            coordinator.enqueueSnackbar(.init(message: "C")),
            .accepted
        )
        host.completeSnackbarUnmount(at: 0)

        XCTAssertNil(visibleSentinel)
        XCTAssertNil(queuedSentinel)
        XCTAssertEqual(host.snackbarCallbacks.count, 2)
        XCTAssertEqual(host.snackbarMessages, ["A", "C"])
        XCTAssertEqual(host.mountedSnackbarCount, 1)
        XCTAssertTrue(scheduler.tasks.isEmpty)

        host.completeSnackbarMount(at: 0, didDisplay: true)

        XCTAssertTrue(scheduler.tasks.isEmpty)
        XCTAssertEqual(host.mountedSnackbarCount, 1)

        host.completeSnackbarMount(at: 1, didDisplay: true)

        XCTAssertEqual(scheduler.tasks.count, 1)
        XCTAssertEqual(
            coordinator.enqueueSnackbar(.init(message: "A", action: .init(title: "Run") {})),
            .accepted
        )
    }

    func test_staleSnackbarTimer_doesNotDismissNewerSnackbarOrDialog() {
        let host = OverlayHostSpy()
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)

        XCTAssertEqual(coordinator.presentDialog(overlayDialogConfiguration) { _ in }, .accepted)
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "A")), .accepted)
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "B")), .accepted)

        let oldTimer = scheduler.tasks[0]
        host.snackbarCallbacks[0].onDismiss()
        XCTAssertEqual(host.snackbarCallbacks.count, 2)

        oldTimer.fireEvenIfCancelled()

        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.mountedSnackbarCount, 1)
        XCTAssertEqual(scheduler.tasks.count, 2)
        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )
    }

    func test_tappedSnackbarAction_survivesLifecycleCleanupAndDoesNotReplayQueue() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        let scheduler = OverlaySchedulerSpy()
        let coordinator = makeOverlayCoordinator(host: host, scheduler: scheduler)
        var actionCount = 0
        var reentrantResult: ClipySnackbar.EnqueueResult?

        XCTAssertEqual(
            coordinator.enqueueSnackbar(
                .init(message: "A", action: .init(title: "Run") {
                    actionCount += 1
                    reentrantResult = coordinator.enqueueSnackbar(.init(message: "C"))
                })
            ),
            .accepted
        )
        XCTAssertEqual(coordinator.enqueueSnackbar(.init(message: "B")), .accepted)

        host.snackbarCallbacks[0].onAction?()
        coordinator.sceneWillResignActive()

        XCTAssertEqual(actionCount, 0)
        XCTAssertEqual(host.snackbarUnmountAnimations, [true, false])

        host.completeSnackbarUnmount(at: 1)
        host.completeSnackbarUnmount(at: 0)
        scheduler.tasks[0].fireEvenIfCancelled()

        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(reentrantResult, .unavailable(.sceneInactive))
        XCTAssertEqual(host.snackbarCallbacks.count, 1)
        XCTAssertEqual(host.mountedSnackbarCount, 0)
    }

}
