//
//  SessionWebViewJavaScriptDialogTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import WebKit
import XCTest

import CoreDesignSystem
@testable import FeatureSession

@MainActor
final class SessionWebViewJavaScriptDialogTests: XCTestCase {
    func test_alertPrimarySelection_completesWebKitOnce() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Alert presented")
        let completed = expectation(description: "Alert completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        var completionCount = 0

        try harness.evaluateJavaScript("alert('Exact website message')") { _, error in
            XCTAssertNil(error)
            completionCount += 1
            completed.fulfill()
        }

        wait(for: [presented], timeout: 3)
        harness.overlay.respond(.selected(button: .single, promptText: nil))
        harness.overlay.respond(.cancelled(.sceneInactive))
        wait(for: [completed], timeout: 3)

        XCTAssertEqual(completionCount, 1)
    }

    func test_confirmCancellation_returnsFalse() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Confirm presented")
        let completed = expectation(description: "Confirm completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        var result: Bool?

        try harness.evaluateJavaScript("confirm('Continue?')") { value, error in
            XCTAssertNil(error)
            result = value as? Bool
            completed.fulfill()
        }

        wait(for: [presented], timeout: 3)
        harness.overlay.respond(.cancelled(.requestCancelled))
        wait(for: [completed], timeout: 3)

        XCTAssertEqual(result, false)
    }

    func test_promptWithoutDefault_primaryUntouched_returnsEmptyText() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Prompt presented")
        let completed = expectation(description: "Prompt completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        var result: String?

        try harness.evaluateJavaScript("prompt('Name')") { value, error in
            XCTAssertNil(error)
            result = value as? String
            completed.fulfill()
        }

        wait(for: [presented], timeout: 3)
        harness.overlay.respond(.selected(button: .primary, promptText: ""))
        wait(for: [completed], timeout: 3)

        XCTAssertEqual(result, "")
    }

    func test_alertAdmissionRejection_completesWebKit() throws {
        let overlay = SessionOverlayRequesterSpy()
        overlay.rejection = .dialogAlreadyPresented
        let harness = try makeHarness(overlay: overlay)
        let completed = expectation(description: "Rejected alert completed")

        try harness.evaluateJavaScript("alert('Continue?')") { _, error in
            XCTAssertNil(error)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertEqual(overlay.dialogConfigurations.count, 1)
        XCTAssertTrue(overlay.acceptedRequestIDs.isEmpty)
    }

    func test_confirmAdmissionRejection_returnsFalse() throws {
        let overlay = SessionOverlayRequesterSpy()
        overlay.rejection = .dialogAlreadyPresented
        let harness = try makeHarness(overlay: overlay)
        let completed = expectation(description: "Rejected confirm completed")
        var result: Bool?

        try harness.evaluateJavaScript("confirm('Continue?')") { value, error in
            XCTAssertNil(error)
            result = value as? Bool
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertEqual(result, false)
    }

    func test_promptAdmissionRejection_returnsNil() throws {
        let overlay = SessionOverlayRequesterSpy()
        overlay.rejection = .dialogAlreadyPresented
        let harness = try makeHarness(overlay: overlay)
        let completed = expectation(description: "Rejected prompt completed")
        var result: Any?

        try harness.evaluateJavaScript("prompt('Name')") { value, error in
            XCTAssertNil(error)
            result = value
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertTrue(result is NSNull)
    }

    func test_alertAfterSessionEnd_completesWithoutOverlayRequest() throws {
        let harness = try makeHarness()
        let completed = expectation(description: "Post-end alert completed")
        harness.sessionWebView?.endSession()

        try harness.evaluateJavaScript("alert('Continue?')") { _, error in
            XCTAssertNil(error)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
    }

    func test_confirmAfterSessionEnd_returnsFalseWithoutOverlayRequest() throws {
        let harness = try makeHarness()
        let completed = expectation(description: "Post-end confirm completed")
        var result: Bool?
        harness.sessionWebView?.endSession()

        try harness.evaluateJavaScript("confirm('Continue?')") { value, error in
            XCTAssertNil(error)
            result = value as? Bool
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertEqual(result, false)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
    }

    func test_promptAfterSessionEnd_returnsNilWithoutOverlayRequest() throws {
        let harness = try makeHarness()
        let completed = expectation(description: "Post-end prompt completed")
        var result: Any?
        harness.sessionWebView?.endSession()

        try harness.evaluateJavaScript("prompt('Name')") { value, error in
            XCTAssertNil(error)
            result = value
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
        XCTAssertTrue(result is NSNull)
        XCTAssertTrue(harness.overlay.dialogConfigurations.isEmpty)
    }

    func test_iframeAlert_usesSubframeMessageAndSource_andCompletes() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Iframe alert presented")
        let completed = expectation(description: "Iframe alert completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        let script = #"""
        window.iframeDialogCompleted = false;
        const iframe = document.createElement('iframe');
        iframe.srcdoc = "<script>alert('Iframe request'); parent.iframeDialogCompleted = true;<\/script>";
        document.body.appendChild(iframe);
        null;
        """#

        try harness.evaluateJavaScript(script) { _, error in
            XCTAssertNil(error)
        }

        wait(for: [presented], timeout: 3)
        XCTAssertEqual(
            harness.overlay.dialogConfigurations.last,
            .message(
                presentation: .websiteRequest(sourceText: "Request from this website"),
                title: "Iframe request",
                body: "",
                buttons: .single(title: "Confirm")
            )
        )
        harness.overlay.respond(.selected(button: .single, promptText: nil))
        try harness.evaluateJavaScript("window.iframeDialogCompleted") { value, error in
            XCTAssertNil(error)
            XCTAssertEqual(value as? Bool, true)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 3)
    }

    func test_responseStartedBeforeSessionEnd_completesOnce_andCancellationTargetsAcceptedID() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Alert presented")
        let completed = expectation(description: "Alert completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        var completionCount = 0

        try harness.evaluateJavaScript("alert('Continue?')") { _, error in
            XCTAssertNil(error)
            completionCount += 1
            completed.fulfill()
        }

        wait(for: [presented], timeout: 3)
        let requestID = try XCTUnwrap(harness.overlay.latestRequestID)
        harness.overlay.beginResponse(.selected(button: .single, promptText: nil))
        harness.sessionWebView?.endSession()
        harness.overlay.completeDeferredResponse()
        wait(for: [completed], timeout: 3)

        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(harness.overlay.cancelledRequestIDs, [requestID])
    }

    func test_sessionEndBeforeResponse_returnsFalseOnce_andLateSelectionIsInert() throws {
        let harness = try makeHarness()
        let presented = expectation(description: "Confirm presented")
        let completed = expectation(description: "Confirm completed")
        harness.overlay.onDialogPresented = { presented.fulfill() }
        var results: [Bool] = []

        try harness.evaluateJavaScript("confirm('Continue?')") { value, error in
            XCTAssertNil(error)
            results.append(value as? Bool ?? false)
            completed.fulfill()
        }

        wait(for: [presented], timeout: 3)
        let requestID = try XCTUnwrap(harness.overlay.latestRequestID)
        harness.sessionWebView?.endSession()
        harness.overlay.respond(.selected(button: .primary, promptText: nil), to: requestID)
        wait(for: [completed], timeout: 3)

        XCTAssertEqual(results, [false])
        XCTAssertEqual(harness.overlay.cancelledRequestIDs, [requestID])
    }

    private func makeHarness(
        overlay: SessionOverlayRequesterSpy = SessionOverlayRequesterSpy()
    ) throws -> JavaScriptDialogHarness {
        let harness = try JavaScriptDialogHarness(overlay: overlay)
        addTeardownBlock { @MainActor in
            harness.tearDown()
        }
        return harness
    }
}
