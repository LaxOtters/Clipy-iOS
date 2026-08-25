//
//  AppOverlayRemovalLifetimeTests.swift
//  Clipy
//
//  Created by 박민서 on 8/25/26.
//

import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlayRemovalLifetimeTests: XCTestCase {
    func test_hostDetachThenShutdown_duringDeferredDialogRemoval_deliversCancellationBeforeRelease() {
        let host = OverlayHostSpy(defersDialogUnmount: true)
        var coordinator: AppOverlayCoordinator? = makeOverlayCoordinator(host: host)
        weak var retainedCoordinator: AppOverlayCoordinator?
        retainedCoordinator = coordinator
        var responses: [ClipyDialog.Response] = []

        let requestResult = coordinator?.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        XCTAssertEqual(requestResult, .accepted)

        coordinator?.hostDidDetach()
        coordinator?.shutdown()
        coordinator = nil

        XCTAssertTrue(responses.isEmpty)

        host.completeDialogUnmount(at: 0)

        XCTAssertEqual(responses, [.cancelled(.hostUnavailable)])
        XCTAssertNil(retainedCoordinator)
    }

    func test_tappedAction_hostDetachThenShutdown_deliversAcceptedActionBeforeRelease() {
        let host = OverlayHostSpy(defersSnackbarUnmount: true)
        var coordinator: AppOverlayCoordinator? = makeOverlayCoordinator(host: host)
        weak var retainedCoordinator: AppOverlayCoordinator?
        retainedCoordinator = coordinator
        var actionCount = 0

        let requestResult = coordinator?.enqueueSnackbar(
            .init(message: "A", action: .init(title: "Run") { actionCount += 1 })
        )
        XCTAssertEqual(requestResult, .accepted)

        host.snackbarCallbacks[0].onAction?()
        coordinator?.hostDidDetach()
        coordinator?.shutdown()
        coordinator = nil

        XCTAssertEqual(actionCount, 0)

        host.completeSnackbarUnmount(at: 1)

        XCTAssertEqual(actionCount, 1)

        host.completeSnackbarUnmount(at: 0)

        XCTAssertEqual(actionCount, 1)
        XCTAssertNil(retainedCoordinator)
    }
}
