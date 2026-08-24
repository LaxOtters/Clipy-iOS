//
//  AppOverlayDialogAdmissionTests.swift
//  Clipy
//
//  Created by 박민서 on 8/25/26.
//

import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlayDialogAdmissionTests: XCTestCase {
    func test_synchronousDisplayFailure_returnsAccepted_beforeResponse() async {
        let host = OverlayHostSpy(dialogMountResult: .unavailable)
        let coordinator = makeOverlayCoordinator(host: host)
        var requestDidReturn = false
        var responseBeforeReturn: Bool?
        var responses: [ClipyDialog.Response] = []
        let responseDelivered = expectation(description: "Display failure response delivered")

        let requestResult = coordinator.presentDialog(overlayDialogConfiguration) { response in
            responseBeforeReturn = !requestDidReturn
            responses.append(response)
            responseDelivered.fulfill()
        }
        requestDidReturn = true

        XCTAssertEqual(requestResult, .accepted)
        XCTAssertTrue(responses.isEmpty)

        await fulfillment(of: [responseDelivered], timeout: 1)

        XCTAssertEqual(responseBeforeReturn, false)
        XCTAssertEqual(responses, [.cancelled(.displayFailed)])
    }

    func test_occupiedHost_rejectsSecondRequest_withoutTouchingIncumbentDialog() {
        let host = OverlayHostSpy()
        let firstCoordinator = makeOverlayCoordinator(host: host)
        let secondCoordinator = makeOverlayCoordinator(host: host)
        var firstResponses: [ClipyDialog.Response] = []
        weak var secondSentinel: LifetimeSentinel?

        XCTAssertEqual(
            firstCoordinator.presentDialog(overlayDialogConfiguration) { firstResponses.append($0) },
            .accepted
        )
        do {
            let sentinel = LifetimeSentinel()
            secondSentinel = sentinel
            XCTAssertEqual(
                secondCoordinator.presentDialog(overlayDialogConfiguration) { [sentinel] _ in _ = sentinel },
                .rejected(.dialogAlreadyPresented)
            )
        }

        secondCoordinator.shutdown()

        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.dialogCallbacks.count, 1)
        XCTAssertNil(secondSentinel)

        host.dialogCallbacks[0](.primary, nil)

        XCTAssertEqual(firstResponses, [.selected(button: .primary, promptText: nil)])
    }

    func test_unavailableAdmission_rejectsDialog_withoutRetainingResponse() {
        let host = OverlayHostSpy(dialogMountAdmission: .unavailable)
        let coordinator = makeOverlayCoordinator(host: host)
        weak var weakSentinel: LifetimeSentinel?

        do {
            let sentinel = LifetimeSentinel()
            weakSentinel = sentinel
            XCTAssertEqual(
                coordinator.presentDialog(overlayDialogConfiguration) { [sentinel] _ in _ = sentinel },
                .rejected(.hostUnavailable)
            )
        }

        XCTAssertNil(weakSentinel)
        XCTAssertEqual(host.mountedDialogCount, 0)
    }

    func test_selectedDialog_acceptsReentrantRequest_onlyAfterUnmount() {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        let coordinator = makeOverlayCoordinator(host: host)
        var reentrantRequestResult: ClipyDialog.RequestResult?

        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in
                reentrantRequestResult = coordinator.presentDialog(overlayDialogConfiguration) { _ in }
            },
            .accepted
        )

        host.dialogCallbacks[0](.primary, nil)

        XCTAssertEqual(
            coordinator.presentDialog(overlayDialogConfiguration) { _ in },
            .rejected(.dialogAlreadyPresented)
        )

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(reentrantRequestResult, .accepted)
    }
}
