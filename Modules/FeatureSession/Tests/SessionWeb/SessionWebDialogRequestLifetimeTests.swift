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
}
