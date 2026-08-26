//
//  SessionWebExternalHandoffTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import XCTest

import CoreDesignSystem
@testable import FeatureSession

@MainActor
final class SessionWebExternalHandoffTests: XCTestCase {
    func test_confirmingExternalOpen_opensOriginalURLOnce() async throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "mailto:help@example.com?subject=Clipy"))

        sut.presentExternalOpenConfirmation(url: url)
        overlay.respond(.selected(button: .primary, promptText: nil))

        let didOpen = await waitUntil { opener.openedURLs == [url] }
        XCTAssertTrue(didOpen)
        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }

    func test_cancellingExternalOpen_doesNotCallOpener() throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut.presentExternalOpenConfirmation(url: url)
        overlay.respond(.selected(button: .secondary, promptText: nil))

        XCTAssertTrue(opener.openedURLs.isEmpty)
    }

    func test_rejectedExternalOpenDialog_doesNotCallOpener() throws {
        let overlay = SessionOverlayRequesterSpy()
        overlay.rejection = .dialogAlreadyPresented
        let opener = SessionURLOpenerSpy()
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut.presentExternalOpenConfirmation(url: url)

        XCTAssertTrue(opener.openedURLs.isEmpty)
    }

    func test_endingSessionBeforeExternalSelection_cancelsRequest_withoutCallingOpener() throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut.presentExternalOpenConfirmation(url: url)
        let requestID = try XCTUnwrap(overlay.latestRequestID)

        sut.endSession()

        XCTAssertEqual(overlay.cancelledRequestIDs, [requestID])
        XCTAssertTrue(opener.openedURLs.isEmpty)
        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }

    func test_failedExternalOpen_whileSessionActive_showsFailureMessage() async throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        opener.result = false
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut.presentExternalOpenConfirmation(url: url)
        overlay.respond(.selected(button: .primary, promptText: nil))

        let didShowFailure = await waitUntil { overlay.snackbarRequests.count == 1 }
        XCTAssertTrue(didShowFailure)
        XCTAssertEqual(overlay.snackbarRequests.map(\.message), ["Couldn't open external app"])
    }

    func test_failedExternalOpen_afterSessionEnds_doesNotShowSnackbar() async throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        opener.defersResult = true
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut.presentExternalOpenConfirmation(url: url)
        overlay.respond(.selected(button: .primary, promptText: nil))
        let didStartOpen = await waitUntil { opener.openedURLs == [url] }
        XCTAssertTrue(didStartOpen)

        sut.endSession()
        opener.complete(with: false)
        await Task.yield()

        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }

    func test_confirmedExternalOpen_afterSessionIsReleased_stillOpensWithoutFailureMessage() async throws {
        let overlay = SessionOverlayRequesterSpy()
        let opener = SessionURLOpenerSpy()
        opener.result = false
        var sut: SessionWebView? = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay, opener: opener)
        )
        let url = try XCTUnwrap(URL(string: "custom-scheme://continue"))

        sut?.presentExternalOpenConfirmation(url: url)
        overlay.beginResponse(.selected(button: .primary, promptText: nil))
        sut?.endSession()
        weak let weakOwner = sut
        sut = nil

        let didRelease = await waitUntil { weakOwner == nil }
        XCTAssertTrue(didRelease)
        overlay.completeDeferredResponse()

        let didOpen = await waitUntil { opener.openedURLs == [url] }
        XCTAssertTrue(didOpen)
        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }

    func test_unsupportedDownload_whileSessionActive_showsExactMessage() {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))

        sut.showUnsupportedDownloadMessage()

        XCTAssertEqual(overlay.snackbarRequests.map(\.message), ["Downloads aren't supported"])
    }

    func test_unsupportedDownload_afterSessionEnds_doesNotShowSnackbar() {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))

        sut.endSession()
        sut.showUnsupportedDownloadMessage()

        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }
}
