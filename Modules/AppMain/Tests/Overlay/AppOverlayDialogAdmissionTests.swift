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

        let requestResult = coordinator.presentDialog(overlayDialogConfiguration) { response in
            responseBeforeReturn = !requestDidReturn
            responses.append(response)
        }
        requestDidReturn = true

        XCTAssertEqual(requestResult, .accepted)
        XCTAssertTrue(responses.isEmpty)

        await Task.yield()

        XCTAssertEqual(responseBeforeReturn, false)
        XCTAssertEqual(responses, [.cancelled(.displayFailed)])
    }

    func test_occupiedHost_keepsIncumbentDialog_andFailsSecondCoordinatorAfterAdmission() async {
        let host = OverlayHostSpy()
        let firstCoordinator = makeOverlayCoordinator(host: host)
        let secondCoordinator = makeOverlayCoordinator(host: host)
        var firstResponses: [ClipyDialog.Response] = []
        var secondResponses: [ClipyDialog.Response] = []

        XCTAssertEqual(
            firstCoordinator.presentDialog(overlayDialogConfiguration) { firstResponses.append($0) },
            .accepted
        )
        XCTAssertEqual(
            secondCoordinator.presentDialog(overlayDialogConfiguration) { secondResponses.append($0) },
            .accepted
        )

        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.dialogCallbacks.count, 1)
        XCTAssertTrue(secondResponses.isEmpty)

        await Task.yield()

        XCTAssertEqual(secondResponses, [.cancelled(.displayFailed)])
        XCTAssertEqual(host.mountedDialogCount, 1)
        XCTAssertEqual(host.dialogCallbacks.count, 1)

        host.dialogCallbacks[0](.primary, nil)

        XCTAssertEqual(firstResponses, [.selected(button: .primary, promptText: nil)])
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
