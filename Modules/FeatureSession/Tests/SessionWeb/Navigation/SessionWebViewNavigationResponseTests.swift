//
//  SessionWebViewNavigationResponseTests.swift
//  Clipy
//
//  Created by 박민서 on 8/27/26.
//

import Foundation
import WebKit
import XCTest

import RxSwift

@testable import FeatureSession

@MainActor
final class SessionWebViewNavigationResponseTests: XCTestCase {
    func test_unsupportedMainFrameResponse_showsMessage_withoutBrowserFallback() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let url = server.url(path: "/unsupported-download")
        let messagePresented = expectation(description: "unsupported download message")
        harness.overlay.onSnackbarEnqueued = { _ in
            if harness.overlay.snackbarRequests.count == 1 {
                messagePresented.fulfill()
            }
        }

        harness.sessionWebView.load(url: url)

        XCTAssertEqual(XCTWaiter.wait(for: [messagePresented], timeout: 10), .completed)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
        XCTAssertTrue(harness.opener.openedURLs.isEmpty)
        XCTAssertEqual(
            harness.overlay.snackbarRequests.map(\.message),
            ["Downloads aren't supported"]
        )
        XCTAssertEqual(
            server.receipts.filter { $0.path == "/unsupported-download" },
            [LocalHTTPRequest(method: "GET", path: "/unsupported-download", body: Data())]
        )
    }

    func test_displayableAttachmentResponse_showsMessage_withoutBrowserFallback() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let url = server.url(path: "/displayable-attachment")
        let messagePresented = expectation(description: "attachment message")
        harness.overlay.onSnackbarEnqueued = { _ in
            if harness.overlay.snackbarRequests.count == 1 {
                messagePresented.fulfill()
            }
        }

        harness.sessionWebView.load(url: url)

        XCTAssertEqual(XCTWaiter.wait(for: [messagePresented], timeout: 10), .completed)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
        XCTAssertTrue(harness.opener.openedURLs.isEmpty)
        XCTAssertEqual(
            harness.overlay.snackbarRequests.map(\.message),
            ["Downloads aren't supported"]
        )
        XCTAssertEqual(
            server.receipts.filter { $0.path == "/displayable-attachment" },
            [LocalHTTPRequest(method: "GET", path: "/displayable-attachment", body: Data())]
        )
    }

    func test_unsupportedPOSTResponse_doesNotReplayRequest_orOpenBrowserFallback() throws {
        let server = try LocalHTTPServer()
        let harness = SessionWebViewNewWindowHarness()
        addTeardownBlock {
            harness.tearDown()
            server.stop()
        }
        let startURL = server.url(path: "/unsupported-post-start")
        let messagePresented = expectation(description: "unsupported POST message")
        let replayedGET = expectation(description: "replayed GET request")
        replayedGET.isInverted = true
        harness.overlay.onSnackbarEnqueued = { _ in
            if harness.overlay.snackbarRequests.count == 1 {
                messagePresented.fulfill()
            }
        }
        server.observeReceipts { request in
            if request.path == "/unsupported-post", request.method == "GET" {
                replayedGET.fulfill()
            }
        }

        try waitForNavigationFinish(on: harness.sessionWebView, step: "load unsupported POST fixture") {
            harness.sessionWebView.load(url: startURL)
        }

        try evaluateJavaScript(
            "document.getElementById('unsupported-post-form').requestSubmit()",
            in: harness.mainWebView
        )

        XCTAssertEqual(XCTWaiter.wait(for: [messagePresented], timeout: 10), .completed)
        XCTAssertEqual(XCTWaiter.wait(for: [replayedGET], timeout: 0.5), .completed)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
        XCTAssertTrue(harness.opener.openedURLs.isEmpty)
        XCTAssertEqual(
            harness.overlay.snackbarRequests.map(\.message),
            ["Downloads aren't supported"]
        )
        XCTAssertEqual(
            server.receipts.filter { $0.path == "/unsupported-post" },
            [
                LocalHTTPRequest(
                    method: "POST",
                    path: "/unsupported-post",
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
}
