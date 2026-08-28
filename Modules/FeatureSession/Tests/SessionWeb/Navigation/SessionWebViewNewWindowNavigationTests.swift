//
//  SessionWebViewNewWindowNavigationTests.swift
//  Clipy
//
//  Created by 박민서 on 8/25/26.
//

import Foundation
import WebKit
import XCTest

import RxSwift

@testable import FeatureSession

@MainActor
final class SessionWebViewNewWindowNavigationTests: XCTestCase {
    func test_httpAndHttpsURLs_loadInMain_forNewWindowNavigation() {
        XCTAssertTrue(
            SessionWebView.shouldLoadNewWindowRequestInMain(
                URL(string: "http://shop.example/item")
            )
        )
        XCTAssertTrue(
            SessionWebView.shouldLoadNewWindowRequestInMain(
                URL(string: "HTTPS://shop.example/checkout")
            )
        )
    }

    func test_missingURL_keepsCurrentPageUnchanged() {
        XCTAssertFalse(SessionWebView.shouldLoadNewWindowRequestInMain(nil))
    }

    func test_exactAboutBlank_keepsCurrentPageUnchanged() {
        XCTAssertFalse(
            SessionWebView.shouldLoadNewWindowRequestInMain(
                URL(string: "about:blank")
            )
        )
    }

    func test_nonWebURL_keepsCurrentPageUnchanged_withoutExternalSideEffect() {
        let urls = [
            URL(string: "mailto:help@example.com"),
            URL(string: "custom-scheme://open"),
            URL(string: "blob:https://shop.example/id"),
            URL(string: "file:///tmp/local.html")
        ]

        XCTAssertTrue(urls.allSatisfy { url in
            !SessionWebView.shouldLoadNewWindowRequestInMain(url)
        })
    }

    func test_newWindowDownloadIntent_doesNotLoadRequestInMain() {
        XCTAssertFalse(
            SessionWebView.shouldLoadNewWindowRequestInMain(
                URL(string: "https://shop.example/export.csv"),
                shouldPerformDownload: true
            )
        )
    }

    func test_newWindowDownloadIntent_requestsBrowserFallback_withoutLoadingDestinationInMain() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let startURL = server.url(path: "/download-start")
        let dialogPresented = expectation(description: "browser fallback dialog")
        let destinationReceived = expectation(description: "download destination request")
        destinationReceived.isInverted = true
        harness.overlay.onDialogPresented = { dialogPresented.fulfill() }
        server.observeReceipts { request in
            if request.path == "/download-destination" {
                destinationReceived.fulfill()
            }
        }

        try waitForNavigationFinish(on: harness.sessionWebView, step: "load download fixture") {
            harness.sessionWebView.load(url: startURL)
        }

        try evaluateJavaScript(
            "document.getElementById('download-link').click()",
            in: harness.mainWebView
        )

        XCTAssertEqual(XCTWaiter.wait(for: [dialogPresented], timeout: 10), .completed)
        XCTAssertEqual(XCTWaiter.wait(for: [destinationReceived], timeout: 0.5), .completed)
        XCTAssertEqual(harness.sessionWebView.currentURL, startURL)
        XCTAssertEqual(
            harness.overlay.dialogConfigurations,
            [SessionWebView.browserFallbackConfiguration]
        )
        XCTAssertTrue(server.receipts.filter { $0.path == "/download-destination" }.isEmpty)
        XCTAssertTrue(harness.opener.openedURLs.isEmpty)
        XCTAssertTrue(harness.overlay.snackbarRequests.isEmpty)
    }

    func test_newWindowGET_loadsDestinationInSessionWebView_andKeepsNativeBackHistory() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let startURL = server.url(path: "/get-start")
        let destinationURL = server.url(path: "/get-destination")

        try waitForNavigationFinish(on: harness.sessionWebView, step: "load GET fixture") {
            harness.sessionWebView.load(url: startURL)
        }

        try waitForNavigationFinish(on: harness.sessionWebView, step: "open new-window GET in session") {
            try evaluateJavaScript(
                "document.getElementById('get-link').click()",
                in: harness.mainWebView
            )
        }

        let destinationState = try waitForBrowserState(
            on: harness.sessionWebView,
            step: "new-window GET destination and back control"
        ) {
            $0.canGoBack
        }
        XCTAssertEqual(harness.sessionWebView.currentURL, destinationURL)
        XCTAssertTrue(destinationState.canReload)
        XCTAssertEqual(
            server.receipts.filter { $0.path == "/get-destination" },
            [LocalHTTPRequest(method: "GET", path: "/get-destination", body: Data())]
        )

        try waitForNavigationFinish(on: harness.sessionWebView, step: "return through native history") {
            harness.sessionWebView.goBack()
        }

        let restoredState = try waitForBrowserState(
            on: harness.sessionWebView,
            step: "GET fixture restored after native back"
        ) {
            $0.canGoForward
        }
        XCTAssertEqual(harness.sessionWebView.currentURL, startURL)
        XCTAssertTrue(restoredState.canReload)
    }

    func test_newWindowFormPOST_preservesMethodAndBody_withOneDestinationReceipt() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let startURL = server.url(path: "/post-start")
        let destinationURL = server.url(path: "/post-destination")

        try waitForNavigationFinish(on: harness.sessionWebView, step: "load POST fixture") {
            harness.sessionWebView.load(url: startURL)
        }

        try waitForNavigationFinish(on: harness.sessionWebView, step: "open new-window POST in session") {
            try evaluateJavaScript(
                "document.getElementById('post-form').requestSubmit()",
                in: harness.mainWebView
            )
        }

        XCTAssertEqual(harness.sessionWebView.currentURL, destinationURL)
        XCTAssertEqual(
            server.receipts.filter { $0.path == "/post-destination" },
            [
                LocalHTTPRequest(
                    method: "POST",
                    path: "/post-destination",
                    body: Data("item=clipy&count=1".utf8)
                )
            ]
        )
    }

    private func evaluateJavaScript(_ script: String, in webView: WKWebView) throws {
        webView.evaluateJavaScript(script) { _, error in
            if let error {
                XCTFail("JavaScript action failed: \(error)")
            }
        }
    }

    private func waitForNavigationFinish(
        on sut: SessionWebView,
        step: String,
        action: () throws -> Void
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
            throw NewWindowNavigationTestError.timedOut
        }
    }

    private func waitForBrowserState(
        on sut: SessionWebView,
        step: String,
        predicate: @escaping (SessionBrowserState) -> Bool
    ) throws -> SessionBrowserState {
        let completed = expectation(description: step)
        var matchedState: SessionBrowserState?
        let disposable = sut.rx.browserState
            .asObservable()
            .filter(predicate)
            .take(1)
            .subscribe(onNext: { state in
                matchedState = state
                completed.fulfill()
            })

        let result = XCTWaiter.wait(for: [completed], timeout: 10)
        disposable.dispose()

        guard result == .completed, let matchedState else {
            XCTFail("Timed out while waiting for \(step). Current URL: \(String(describing: sut.currentURL))")
            throw NewWindowNavigationTestError.timedOut
        }

        return matchedState
    }
}
