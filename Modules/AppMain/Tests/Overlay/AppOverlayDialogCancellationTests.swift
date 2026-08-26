//
//  AppOverlayDialogCancellationTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlayDialogCancellationTests: XCTestCase {
    func test_dialogCancellation_releasesSlotBeforeResponseAndUsesCurrentLifecycleForReentry() {
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

        coordinator.sceneWillResignActive()

        XCTAssertTrue(responses.isEmpty)
        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.sceneInactive)])
        XCTAssertEqual(reentrantRequestResult, .rejected(.sceneInactive))
    }

    func test_cancelDialog_cancelsMatchingActiveRequest_withoutAnimation() throws {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        let requestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        coordinator.cancelDialog(requestID)

        XCTAssertEqual(host.dialogUnmountAnimations, [false])
        XCTAssertTrue(responses.isEmpty)

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.requestCancelled)])
    }

    func test_cancelDialog_whileEntering_ignoresLateMountCompletionAndRespondsOnce() throws {
        let host = OverlayHostSpy(dialogMountResult: nil, defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        let requestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        coordinator.cancelDialog(requestID)

        XCTAssertEqual(host.dialogUnmountAnimations, [false])
        XCTAssertTrue(responses.isEmpty)

        host.completeDialogMount(at: 0, didDisplay: true)
        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.requestCancelled)])
    }

    func test_cancelDialog_keepsUnknownAndSelectionFirstRequestsInert() throws {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        let requestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        coordinator.cancelDialog(.init())
        host.dialogCallbacks[0](.primary, "chosen")
        coordinator.cancelDialog(requestID)

        XCTAssertEqual(host.dialogUnmountAnimations, [true])

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.selected(button: .primary, promptText: "chosen")])
    }

    func test_cancelDialog_thenLateSelection_keepsRequestCancellationResponseOnce() throws {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        let requestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        coordinator.cancelDialog(requestID)
        host.dialogCallbacks[0](.primary, "late")
        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(host.dialogUnmountAnimations, [false])
        XCTAssertEqual(responses, [.cancelled(.requestCancelled)])
    }

    func test_cancelDialog_thenLifecycleCleanup_keepsRequestCancellationResponseOnce() throws {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var responses: [ClipyDialog.Response] = []
        let requestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        coordinator.cancelDialog(requestID)
        coordinator.sceneWillResignActive()

        XCTAssertEqual(host.dialogUnmountAnimations, [false, false])
        XCTAssertTrue(responses.isEmpty)

        host.completeDialogUnmount(at: 1)
        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.requestCancelled)])
    }

    func test_cancelDialog_keepsCompletedAndCrossCoordinatorRequestIDsInert() throws {
        let firstHost = OverlayHostSpy()
        let secondHost = OverlayHostSpy()
        let firstCoordinator = makeOverlayCoordinator(host: firstHost)
        let secondCoordinator = makeOverlayCoordinator(host: secondHost)
        var firstResponses: [ClipyDialog.Response] = []
        var secondResponses: [ClipyDialog.Response] = []
        let firstRequestID = try acceptedDialogRequestID(
            firstCoordinator.presentDialog(overlayDialogConfiguration) { firstResponses.append($0) }
        )
        let secondRequestID = try acceptedDialogRequestID(
            secondCoordinator.presentDialog(overlayDialogConfiguration) { secondResponses.append($0) }
        )

        secondCoordinator.cancelDialog(firstRequestID)
        firstHost.dialogCallbacks[0](.primary, nil)
        firstCoordinator.cancelDialog(firstRequestID)

        XCTAssertEqual(firstResponses, [.selected(button: .primary, promptText: nil)])
        XCTAssertTrue(secondResponses.isEmpty)
        XCTAssertEqual(secondHost.mountedDialogCount, 1)

        secondCoordinator.cancelDialog(secondRequestID)

        XCTAssertEqual(secondResponses, [.cancelled(.requestCancelled)])
    }

    func test_cancelDialog_withCompletedRequestID_keepsNewerRequestOnSameCoordinatorActive() throws {
        let host = OverlayHostSpy()
        let coordinator = makeOverlayCoordinator(host: host)
        var firstResponses: [ClipyDialog.Response] = []
        var secondResponses: [ClipyDialog.Response] = []
        let firstRequestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { firstResponses.append($0) }
        )
        host.dialogCallbacks[0](.primary, nil)
        let secondRequestID = try acceptedDialogRequestID(
            coordinator.presentDialog(overlayDialogConfiguration) { secondResponses.append($0) }
        )

        coordinator.cancelDialog(firstRequestID)

        XCTAssertEqual(firstResponses, [.selected(button: .primary, promptText: nil)])
        XCTAssertTrue(secondResponses.isEmpty)
        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.dialogUnmountAnimations, [true])

        coordinator.cancelDialog(secondRequestID)

        XCTAssertEqual(secondResponses, [.cancelled(.requestCancelled)])
    }
}
