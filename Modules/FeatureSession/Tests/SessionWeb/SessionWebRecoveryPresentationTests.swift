//
//  SessionWebRecoveryPresentationTests.swift
//  Clipy
//
//  Created by 박민서 on 8/27/26.
//

import UIKit
import WebKit
import XCTest

import CoreDesignSystem
import RxSwift

@testable import FeatureSession

@MainActor
final class SessionWebRecoveryPresentationTests: XCTestCase {
    func test_provisionalFailure_withUsablePage_enqueuesActionlessSnackbar() throws {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))
        let currentURL = try loadFixture(on: sut)
        let error = navigationError(.cannotConnectToHost)

        sut.handleNavigationFailure(
            .provisional(SessionWebNavigationFailureContext(error: error))
        )

        XCTAssertEqual(sut.currentURL, currentURL)
        XCTAssertEqual(overlay.snackbarRequests.map(\.message), ["Couldn't load this page"])
        XCTAssertNil(overlay.snackbarRequests.first?.action)
    }

    func test_mountedError_isReplacedPreservedForCancelAndRemovedOnFinish() {
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: SessionOverlayRequesterSpy())
        )
        let webView = nativeWebView(in: sut)

        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.timedOut)))
        )
        let firstContent = errorContent(in: sut)
        XCTAssertNotNil(firstContent)
        XCTAssertEqual(firstContent?.superview?.backgroundColor, .systemBackground)
        XCTAssertFalse(webView?.isUserInteractionEnabled ?? true)
        XCTAssertTrue(webView?.accessibilityElementsHidden ?? false)

        sut.handleNavigationFailure(
            .provisional(SessionWebNavigationFailureContext(error: navigationError(.unsupportedURL)))
        )
        let replacement = errorContent(in: sut)
        XCTAssertNotNil(replacement)
        XCTAssertFalse(firstContent === replacement)

        sut.handleNavigationFailure(
            .provisional(SessionWebNavigationFailureContext(error: navigationError(.cancelled)))
        )
        XCTAssertTrue(replacement === errorContent(in: sut))

        sut.webView(WKWebView(), didFinish: nil)

        XCTAssertNil(errorContent(in: sut))
        XCTAssertTrue(webView?.isUserInteractionEnabled ?? false)
        XCTAssertFalse(webView?.accessibilityElementsHidden ?? true)
    }

    func test_homeRecovery_marksSessionInactiveBeforeRoute_andClaimsActionOnce() throws {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))
        var routeCount = 0
        sut.onRecoveryGoHome = {
            routeCount += 1
            sut.handleNavigationFailure(
                .committed(
                    SessionWebNavigationFailureContext(
                        error: self.navigationError(.cannotConnectToHost)
                    )
                )
            )
        }

        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.unsupportedURL)))
        )

        let button = try XCTUnwrap(firstControl(in: sut))
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(routeCount, 1)
        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
    }

    func test_processTermination_replacesMountedOrdinaryError() {
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: SessionOverlayRequesterSpy())
        )
        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.timedOut)))
        )
        let ordinaryContent = errorContent(in: sut)

        sut.webViewWebContentProcessDidTerminate(WKWebView())

        XCTAssertNotNil(errorContent(in: sut))
        XCTAssertFalse(ordinaryContent === errorContent(in: sut))
    }

    func test_retryAction_performsNativeReload_whenTappedRepeatedly() throws {
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: SessionOverlayRequesterSpy())
        )
        _ = try loadFixture(on: sut)
        XCTAssertEqual(try navigationType(in: sut), "navigate")
        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.timedOut)))
        )

        try waitForNavigationFinish(on: sut, step: "retry current page") {
            let button = try XCTUnwrap(recoveryButton(in: sut))
            button.sendActions(for: .touchUpInside)
            button.sendActions(for: .touchUpInside)
        }

        XCTAssertEqual(try navigationType(in: sut), "reload")
    }

    func test_goBackAction_returnsToPreviousHistoryItem_whenTappedRepeatedly() throws {
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: SessionOverlayRequesterSpy())
        )
        let firstURL = try loadFixture(on: sut, name: "first")
        _ = try loadFixture(on: sut, name: "second")
        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.unsupportedURL)))
        )

        try waitForNavigationFinish(on: sut, step: "return to previous page") {
            let button = try XCTUnwrap(recoveryButton(in: sut))
            button.sendActions(for: .touchUpInside)
            button.sendActions(for: .touchUpInside)
        }

        XCTAssertEqual(sut.currentURL, firstURL)
    }

    func test_reopenAction_performsNativeReload_whenTappedRepeatedly() throws {
        let sut = SessionWebView(
            dependencies: makeSessionDependencies(overlay: SessionOverlayRequesterSpy())
        )
        _ = try loadFixture(on: sut)
        XCTAssertEqual(try navigationType(in: sut), "navigate")
        sut.handleWebContentProcessTermination()

        try waitForNavigationFinish(on: sut, step: "reopen terminated page") {
            let button = try XCTUnwrap(recoveryButton(in: sut))
            button.sendActions(for: .touchUpInside)
            button.sendActions(for: .touchUpInside)
        }

        XCTAssertEqual(try navigationType(in: sut), "reload")
    }

    func test_displayableHTTPErrorAndImageResponses_remainNativeWebKitContent() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        var failures: [SessionWebNavigationFailure] = []
        let disposable = harness.sessionWebView.rx.navigationFailure
            .emit(onNext: { failures.append($0) })
        addTeardownBlock {
            disposable.dispose()
            harness.tearDown()
            server.stop()
        }

        for status in [404, 500] {
            try waitForNavigationFinish(on: harness.sessionWebView, step: "display HTTP \(status)") {
                harness.sessionWebView.load(url: server.url(path: "/status/\(status)"))
            }
            XCTAssertEqual(
                try evaluateJavaScript("document.body.textContent", in: harness.sessionWebView) as? String,
                "Visible \(status)"
            )
            XCTAssertNil(errorContent(in: harness.sessionWebView))
        }

        try waitForNavigationFinish(on: harness.sessionWebView, step: "display image content") {
            harness.sessionWebView.load(url: server.url(path: "/content/image"))
        }

        XCTAssertTrue(failures.isEmpty)
        XCTAssertNil(errorContent(in: harness.sessionWebView))
    }

    func test_sessionEnd_discardsMountedError_andSuppressesLaterPresentation() {
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))
        let webView = nativeWebView(in: sut)
        sut.handleNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: navigationError(.timedOut)))
        )

        sut.endSession()
        sut.handleNavigationFailure(
            .provisional(
                SessionWebNavigationFailureContext(
                    error: navigationError(.cannotConnectToHost)
                )
            )
        )
        sut.webViewWebContentProcessDidTerminate(WKWebView())

        XCTAssertNil(errorContent(in: sut))
        XCTAssertTrue(overlay.snackbarRequests.isEmpty)
        XCTAssertTrue(webView?.isUserInteractionEnabled ?? false)
        XCTAssertFalse(webView?.accessibilityElementsHidden ?? true)
    }

    private func navigationError(_ code: URLError.Code) -> NSError {
        NSError(domain: NSURLErrorDomain, code: code.rawValue)
    }

    private func loadFixture(on sut: SessionWebView, name: String = "recovery") throws -> URL {
        let fixtureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString).html")
        try Data("<html><body>Recovery fixture</body></html>".utf8).write(to: fixtureURL)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: fixtureURL)
        }

        let loaded = expectation(description: "Recovery fixture loaded")
        let disposable = sut.rx.navigationFinished
            .asObservable()
            .take(1)
            .subscribe(onNext: { loaded.fulfill() })
        sut.load(url: fixtureURL)
        let result = XCTWaiter.wait(for: [loaded], timeout: 10)
        disposable.dispose()
        XCTAssertEqual(result, .completed)
        return fixtureURL
    }

    private func navigationType(in sut: SessionWebView) throws -> String {
        let completed = expectation(description: "Read WebKit navigation type")
        var navigationType: String?
        var receivedError: Error?
        let script = "performance.getEntriesByType('navigation')[0].type"
        try XCTUnwrap(nativeWebView(in: sut)).evaluateJavaScript(script) { value, error in
            navigationType = value as? String
            receivedError = error
            completed.fulfill()
        }
        XCTAssertEqual(XCTWaiter.wait(for: [completed], timeout: 10), .completed)
        XCTAssertNil(receivedError)
        return try XCTUnwrap(navigationType)
    }

    private func evaluateJavaScript(_ script: String, in sut: SessionWebView) throws -> Any? {
        let completed = expectation(description: "Evaluate WebKit content")
        var result: Any?
        var receivedError: Error?
        try XCTUnwrap(nativeWebView(in: sut)).evaluateJavaScript(script) { value, error in
            result = value
            receivedError = error
            completed.fulfill()
        }
        XCTAssertEqual(XCTWaiter.wait(for: [completed], timeout: 10), .completed)
        XCTAssertNil(receivedError)
        return result
    }

    private func waitForNavigationFinish(
        on sut: SessionWebView, step: String, action: () throws -> Void
    ) throws {
        let completed = expectation(description: step)
        let disposable = sut.rx.navigationFinished
            .asObservable()
            .take(1)
            .subscribe(onNext: { completed.fulfill() })

        try action()
        let result = XCTWaiter.wait(for: [completed], timeout: 10)
        disposable.dispose()

        guard result == .completed else {
            XCTFail("Timed out while waiting for \(step). Current URL: \(String(describing: sut.currentURL))")
            throw RecoveryStepFailure.timedOut
        }
    }

    private func nativeWebView(in view: UIView) -> WKWebView? {
        descendants(of: view).compactMap { $0 as? WKWebView }.first
    }

    private func errorContent(in view: UIView) -> ClipyErrorContentView? {
        descendants(of: view).compactMap { $0 as? ClipyErrorContentView }.first
    }

    private func firstControl(in view: UIView) -> UIControl? {
        descendants(of: view).compactMap { $0 as? UIControl }.first
    }

    private func recoveryButton(in view: UIView) -> UIControl? {
        errorContent(in: view).flatMap(firstControl)
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }
}

extension SessionWebRecoveryPresentationTests {
    func test_sameURLReloadFailure_keepsCommittedPage_andEnqueuesActionlessSnackbar() throws {
        let server = try LocalHTTPServer()
        let overlay = SessionOverlayRequesterSpy()
        let sut = SessionWebView(dependencies: makeSessionDependencies(overlay: overlay))
        let pageURL = server.url(path: "/same-url-recovery")
        addTeardownBlock {
            server.stop()
        }

        try waitForNavigationFinish(on: sut, step: "load same-URL recovery fixture") {
            sut.load(url: pageURL)
        }
        server.stop()

        let failed = expectation(description: "same-URL reload fails provisionally")
        let disposable = sut.rx.navigationFailure
            .asObservable()
            .take(1)
            .subscribe(onNext: { failure in
                guard case .provisional = failure else {
                    return XCTFail("Expected provisional reload failure, got \(failure).")
                }
                failed.fulfill()
            })

        sut.reload()
        XCTAssertEqual(XCTWaiter.wait(for: [failed], timeout: 10), .completed)
        disposable.dispose()

        XCTAssertEqual(sut.currentURL, pageURL)
        XCTAssertEqual(overlay.snackbarRequests.map(\.message), ["Couldn't load this page"])
        XCTAssertNil(overlay.snackbarRequests.first?.action)
        XCTAssertNil(errorContent(in: sut))
    }
}

private enum RecoveryStepFailure: Error {
    case timedOut
}
