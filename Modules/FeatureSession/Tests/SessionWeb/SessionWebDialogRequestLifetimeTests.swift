//
//  SessionWebDialogRequestLifetimeTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import XCTest

import CoreDesignSystem
@testable import FeatureSession

@MainActor
final class SessionWebDialogRequestLifetimeTests: XCTestCase {
    func test_processTermination_cancelsAcceptedDialogsBeforeMountingRecovery_exactlyOnce() throws {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(overlayRequester: overlay)
        var completionCount = 0
        var recoveryWasMountedDuringCancellation = false

        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Pending", sourceURL: nil),
            onResponse: { _ in completionCount += 1 },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        let acceptedRequestID = try XCTUnwrap(overlay.latestRequestID)
        overlay.onCancelDialog = { _ in
            recoveryWasMountedDuringCancellation = recoveryWasMountedDuringCancellation
                || self.hasMountedRecovery(in: sut)
        }

        sut.handleWebContentProcessTermination()
        sut.handleWebContentProcessTermination()

        XCTAssertEqual(overlay.cancelledRequestIDs, [acceptedRequestID])
        XCTAssertEqual(completionCount, 1)
        XCTAssertFalse(recoveryWasMountedDuringCancellation)
        XCTAssertTrue(hasMountedRecovery(in: sut))
    }

    func test_processTermination_withDeferredCancellation_mountsRecoveryWithoutWaiting_andKeepsSessionActive() throws {
        let overlay = SessionOverlayRequesterSpy()
        overlay.respondsToCancellation = false
        let sut = SessionWebView(overlayRequester: overlay)
        var completionCount = 0
        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Pending", sourceURL: nil),
            onResponse: { _ in completionCount += 1 },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        let pendingRequestID = try XCTUnwrap(overlay.latestRequestID)

        sut.handleWebContentProcessTermination()
        sut.handleWebContentProcessTermination()

        XCTAssertEqual(overlay.cancelledRequestIDs, [pendingRequestID])
        XCTAssertTrue(hasMountedRecovery(in: sut))
        XCTAssertEqual(completionCount, 0)

        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Next", sourceURL: nil),
            onResponse: { _ in },
            onUnavailable: { XCTFail("Process termination must not end the session") }
        )
        XCTAssertEqual(overlay.acceptedRequestIDs.count, 2)

        overlay.respond(.cancelled(.requestCancelled), to: pendingRequestID)
        XCTAssertEqual(completionCount, 1)
    }

    func test_processTermination_afterUserSelection_doesNotCancelCompletedDialog() {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(overlayRequester: overlay)
        var completionCount = 0
        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Continue?", sourceURL: nil),
            onResponse: { _ in completionCount += 1 },
            onUnavailable: { XCTFail("Expected accepted request") }
        )

        overlay.respond(.selected(button: .single, promptText: nil))
        sut.handleWebContentProcessTermination()

        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(overlay.cancelledRequestIDs.isEmpty)
        XCTAssertTrue(hasMountedRecovery(in: sut))
    }

    func test_webKitCompletionReentersSessionEnd_retiresIDBeforeCompletion() {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(overlayRequester: overlay)
        var completionCount = 0

        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Continue?", sourceURL: nil),
            onResponse: { _ in
                completionCount += 1
                sut.endSession()
            },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        overlay.respond(.selected(button: .single, promptText: nil))

        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(overlay.cancelledRequestIDs.isEmpty)
    }

    func test_cancelResponseReentersSessionEnd_clearsIDBeforeCancellation() throws {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(overlayRequester: overlay)
        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Continue?", sourceURL: nil),
            onResponse: { _ in sut.endSession() },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        let requestID = try XCTUnwrap(overlay.latestRequestID)

        sut.endSession()

        XCTAssertEqual(overlay.cancelledRequestIDs, [requestID])
    }

    func test_endingSessionTwice_keepsCancellationAndCompletionCountsAtOne() throws {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(overlayRequester: overlay)
        var completionCount = 0
        sut.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Continue?", sourceURL: nil),
            onResponse: { _ in completionCount += 1 },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        let requestID = try XCTUnwrap(overlay.latestRequestID)

        sut.endSession()
        sut.endSession()

        XCTAssertEqual(overlay.cancelledRequestIDs, [requestID])
        XCTAssertEqual(completionCount, 1)
    }

    func test_endingFirstSession_cannotCancelSecondSessionRequest() throws {
        let firstOverlay = SessionOverlayRequesterSpy()
        let secondOverlay = SessionOverlayRequesterSpy()
        let first = SessionWebView(overlayRequester: firstOverlay)
        let second = SessionWebView(overlayRequester: secondOverlay)
        first.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "First", sourceURL: nil),
            onResponse: { _ in },
            onUnavailable: { XCTFail("Expected first request") }
        )
        let firstID = try XCTUnwrap(firstOverlay.latestRequestID)
        second.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Second", sourceURL: nil),
            onResponse: { _ in },
            onUnavailable: { XCTFail("Expected second request") }
        )
        let secondID = try XCTUnwrap(secondOverlay.latestRequestID)

        first.endSession()

        XCTAssertEqual(firstOverlay.cancelledRequestIDs, [firstID])
        XCTAssertTrue(secondOverlay.cancelledRequestIDs.isEmpty)
        XCTAssertNotEqual(firstID, secondID)
    }

    func test_releasingSessionWebView_beforeDeferredCancellation_completesCapturedCompletionOnce() async throws {
        let overlay = SessionOverlayRequesterSpy()
        var sut: SessionWebView? = SessionWebView(overlayRequester: overlay)
        var completionCount = 0
        sut?.presentJavaScriptDialog(
            SessionWebView.alertConfiguration(message: "Continue?", sourceURL: nil),
            onResponse: { _ in completionCount += 1 },
            onUnavailable: { XCTFail("Expected accepted request") }
        )
        let requestID = try XCTUnwrap(overlay.latestRequestID)
        overlay.beginResponse(.cancelled(.requestCancelled), to: requestID)
        weak let weakOwner = sut

        sut = nil
        let didRelease = await waitUntil {
            weakOwner == nil
        }
        XCTAssertTrue(didRelease)
        XCTAssertNil(weakOwner)
        overlay.completeDeferredResponse()

        XCTAssertEqual(completionCount, 1)
    }

    private func hasMountedRecovery(in view: UIView) -> Bool {
        descendants(of: view).contains { $0 is ClipyErrorContentView }
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }
}
