//
//  AppOverlayCoordinatorTests.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import UIKit
import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlayCoordinatorTests: XCTestCase {
    func test_presentDialog_rejectsUnavailableHost_withoutRetainingResponse() {
        let host = OverlayHostSpy(isAvailable: false)
        let coordinator = makeOverlayCoordinator(host: host)
        weak var weakSentinel: LifetimeSentinel?

        do {
            let sentinel = LifetimeSentinel()
            weakSentinel = sentinel

            let outcome = coordinator.presentDialog(overlayDialogConfiguration) { [sentinel] _ in
                _ = sentinel
            }

            XCTAssertEqual(outcome, .rejected(.hostUnavailable))
        }

        XCTAssertNil(weakSentinel)
        XCTAssertEqual(host.mountedDialogCount, 0)
    }

    func test_presentDialog_keepsFirstRequest_andDoesNotRetainRejectedResponse() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        weak var rejectedSentinel: LifetimeSentinel?

        assertDialogRequestAccepted(coordinator.presentDialog(overlayDialogConfiguration) { _ in })
        do {
            let sentinel = LifetimeSentinel()
            rejectedSentinel = sentinel
            let outcome = coordinator.presentDialog(overlayDialogConfiguration) { [sentinel] _ in
                _ = sentinel
            }
            XCTAssertEqual(outcome, .rejected(.dialogAlreadyPresented))
        }

        XCTAssertNil(rejectedSentinel)
        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.dialogCallbacks.count, 1)
    }

    func test_oldDialogCallbacks_cannotMutateNewerAcceptedDialog() {
        let host = OverlayHostSpy(dialogMountResult: nil, defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )
        coordinator.sceneWillResignActive()
        XCTAssertTrue(responses.isEmpty)

        coordinator.sceneDidBecomeActive()
        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) },
            .rejected(.dialogAlreadyPresented)
        )
        host.completeDialogMount(at: 0, didDisplay: false)
        host.completeDialogUnmount(at: 0)
        XCTAssertEqual(responses, [.cancelled(.sceneInactive)])

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )
        host.dialogCallbacks[0](.primary, nil)

        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )
        host.dialogCallbacks[1](.secondary, "new")
        host.completeDialogUnmount(at: 1)
        XCTAssertEqual(
            responses,
            [.cancelled(.sceneInactive), .selected(button: .secondary, promptText: "new")]
        )
    }

    func test_dialogDisplayFailure_releasesSlotBeforeResponseAndAllowsReentrantDialog() async {
        let host = OverlayHostSpy(dialogMountResult: .unavailable, defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        var reentrantRequestResult: ClipyDialog.RequestResult?
        weak var weakSentinel: LifetimeSentinel?
        let unmountRequested = expectation(description: "Dialog unmount requested")
        host.onDialogUnmountRequested = { unmountRequested.fulfill() }

        do {
            let sentinel = LifetimeSentinel()
            weakSentinel = sentinel
            assertDialogRequestAccepted(
                coordinator.presentDialog(overlayDialogConfiguration) { [sentinel] response in
                    _ = sentinel
                    responses.append(response)
                    reentrantRequestResult = coordinator.presentDialog(overlayDialogConfiguration) { _ in }
                }
            )
        }
        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )
        XCTAssertNotNil(weakSentinel)

        await fulfillment(of: [unmountRequested], timeout: 1)
        host.onDialogUnmountRequested = nil

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.displayFailed)])
        if let reentrantRequestResult {
            assertDialogRequestAccepted(reentrantRequestResult)
        } else {
            XCTFail("Expected a reentrant Dialog request result.")
        }
        XCTAssertNil(weakSentinel)
    }

    func test_selectedDialog_keepsSelectionWhenSceneBecomesInactiveDuringExit() {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )
        host.dialogCallbacks[0](.primary, "snapshot")
        coordinator.sceneWillResignActive()

        XCTAssertTrue(responses.isEmpty)
        XCTAssertEqual(host.dialogUnmountAnimations, [true, false])

        host.completeDialogUnmount(at: 1)
        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.selected(button: .primary, promptText: "snapshot")])
    }

    func test_selectedDialog_hostLoss_releasesSlotBeforeSelectedResponse_andIgnoresStaleCompletion() {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        var reentrantRequestResult: ClipyDialog.RequestResult?

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { response in
                responses.append(response)
                reentrantRequestResult = coordinator.presentDialog(overlayDialogConfiguration) { _ in }
            }
        )

        host.dialogCallbacks[0](.primary, "snapshot")
        coordinator.hostDidDetach()

        XCTAssertTrue(responses.isEmpty)
        XCTAssertEqual(host.dialogUnmountAnimations, [true, false])
        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )

        host.completeDialogUnmount(at: 1)

        XCTAssertEqual(responses, [.selected(button: .primary, promptText: "snapshot")])
        XCTAssertEqual(reentrantRequestResult, .rejected(.hostUnavailable))

        host.completeDialogUnmount(at: 0)
        host.dialogCallbacks[0](.secondary, "stale")

        XCTAssertEqual(responses, [.selected(button: .primary, promptText: "snapshot")])
    }

    func test_shutdown_cancelsDialogAndReleasesAllSnackbarActions() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        weak var visibleSentinel: LifetimeSentinel?
        weak var queuedSentinel: LifetimeSentinel?

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )
        do {
            let visible = LifetimeSentinel()
            let queued = LifetimeSentinel()
            visibleSentinel = visible
            queuedSentinel = queued
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Open") { [visible] in _ = visible })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Open") { [queued] in _ = queued })
                ),
                .accepted
            )
        }

        coordinator.shutdown()

        XCTAssertEqual(responses, [.cancelled(.sceneDisconnected)])
        XCTAssertNil(visibleSentinel)
        XCTAssertNil(queuedSentinel)
        guard case .unavailable = coordinator.enqueueSnackbar(.init(message: "C")) else {
            return XCTFail("A shutdown coordinator must reject new Snackbar requests.")
        }
    }

    func test_hostDetach_cancelsDialogAndReleasesVisibleAndQueuedSnackbarActions() {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        weak var firstSentinel: LifetimeSentinel?
        weak var secondSentinel: LifetimeSentinel?

        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )
        do {
            let first = LifetimeSentinel()
            let second = LifetimeSentinel()
            firstSentinel = first
            secondSentinel = second
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "A", action: .init(title: "Open") { [first] in _ = first })
                ),
                .accepted
            )
            XCTAssertEqual(
                coordinator.enqueueSnackbar(
                    .init(message: "B", action: .init(title: "Open") { [second] in _ = second })
                ),
                .accepted
            )
        }

        coordinator.hostDidDetach()

        XCTAssertEqual(responses, [.cancelled(.hostUnavailable)])
        XCTAssertNil(firstSentinel)
        XCTAssertNil(secondSentinel)
    }

    func test_coordinators_keepSceneStateIndependent() {
        let firstHost = OverlayHostSpy()
        let secondHost = OverlayHostSpy()
        let first = makeOverlayCoordinator(host: firstHost)
        let second = makeOverlayCoordinator(host: secondHost)
        var firstResponses: [ClipyDialog.Response] = []
        var secondResponses: [ClipyDialog.Response] = []

        assertDialogRequestAccepted(
            first.presentDialog(overlayDialogConfiguration) { firstResponses.append($0) }
        )
        assertDialogRequestAccepted(
            second.presentDialog(overlayDialogConfiguration) { secondResponses.append($0) }
        )
        XCTAssertEqual(first.enqueueSnackbar(.init(message: "Same")), .accepted)
        XCTAssertEqual(second.enqueueSnackbar(.init(message: "Same")), .accepted)

        first.sceneWillResignActive()

        XCTAssertEqual(firstResponses, [.cancelled(.sceneInactive)])
        XCTAssertEqual(firstHost.mountedDialogCount, 0)
        XCTAssertEqual(firstHost.mountedSnackbarCount, 0)
        XCTAssertTrue(secondResponses.isEmpty)
        XCTAssertEqual(secondHost.mountedDialogCount, 1)
        XCTAssertEqual(secondHost.mountedSnackbarCount, 1)

        secondHost.snackbarCallbacks[0].onDismiss()
        secondHost.dialogCallbacks[0](.primary, nil)

        XCTAssertEqual(secondResponses, [.selected(button: .primary, promptText: nil)])
        XCTAssertEqual(secondHost.mountedDialogCount, 0)
        XCTAssertEqual(secondHost.mountedSnackbarCount, 0)
    }
}
