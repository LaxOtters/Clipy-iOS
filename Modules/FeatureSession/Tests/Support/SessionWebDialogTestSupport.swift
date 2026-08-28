//
//  SessionWebDialogTestSupport.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import UIKit
import WebKit
import XCTest

import CoreDesignSystem
import RxSwift
@testable import FeatureSession

@MainActor
final class SessionOverlayRequesterSpy: ClipyOverlayRequesting {
    var rejection: ClipyDialog.RequestRejection?
    var onDialogPresented: (() -> Void)?
    var onSnackbarEnqueued: ((ClipySnackbar.Request) -> Void)?
    var onCancelDialog: ((ClipyDialog.RequestID) -> Void)?
    var respondsToCancellation = true

    private(set) var dialogConfigurations: [ClipyDialog.Configuration] = []
    private(set) var acceptedRequestIDs: [ClipyDialog.RequestID] = []
    private(set) var cancelledRequestIDs: [ClipyDialog.RequestID] = []
    private(set) var snackbarRequests: [ClipySnackbar.Request] = []
    private var responses: [ClipyDialog.RequestID: @MainActor (ClipyDialog.Response) -> Void] = [:]
    private var deferredResponse: (@MainActor () -> Void)?

    var latestRequestID: ClipyDialog.RequestID? {
        acceptedRequestIDs.last
    }

    nonisolated init() {}

    func presentDialog(
        _ configuration: ClipyDialog.Configuration,
        response: @escaping @MainActor (ClipyDialog.Response) -> Void
    ) -> ClipyDialog.RequestResult {
        dialogConfigurations.append(configuration)
        onDialogPresented?()

        if let rejection {
            return .rejected(rejection)
        }

        let requestID = ClipyDialog.RequestID()
        acceptedRequestIDs.append(requestID)
        responses[requestID] = response
        return .accepted(requestID)
    }

    func cancelDialog(_ requestID: ClipyDialog.RequestID) {
        cancelledRequestIDs.append(requestID)
        onCancelDialog?(requestID)

        guard respondsToCancellation else {
            return
        }
        respond(.cancelled(.requestCancelled), to: requestID)
    }

    func enqueueSnackbar(_ request: ClipySnackbar.Request) -> ClipySnackbar.EnqueueResult {
        snackbarRequests.append(request)
        onSnackbarEnqueued?(request)
        return .accepted
    }

    func respond(
        _ response: ClipyDialog.Response,
        to requestID: ClipyDialog.RequestID? = nil
    ) {
        guard let requestID = requestID ?? latestRequestID else {
            return
        }
        let callback = responses.removeValue(forKey: requestID)
        callback?(response)
    }

    func beginResponse(
        _ response: ClipyDialog.Response,
        to requestID: ClipyDialog.RequestID? = nil
    ) {
        guard let requestID = requestID ?? latestRequestID else {
            return
        }
        let callback = responses.removeValue(forKey: requestID)
        deferredResponse = {
            callback?(response)
        }
    }

    func completeDeferredResponse() {
        let response = deferredResponse
        deferredResponse = nil
        response?()
    }
}

@MainActor
final class SessionURLOpenerSpy {
    var result = true
    var defersResult = false
    private(set) var openedURLs: [URL] = []
    private var continuation: CheckedContinuation<Bool, Never>?

    func open(_ url: URL) async -> Bool {
        openedURLs.append(url)
        guard defersResult else {
            return result
        }
        return await withCheckedContinuation { continuation = $0 }
    }

    func complete(with result: Bool) {
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(returning: result)
    }
}

@MainActor
func makeSessionDependencies(
    overlay: SessionOverlayRequesterSpy,
    opener: SessionURLOpenerSpy? = nil
) -> SessionFeature.Dependencies {
    let opener = opener ?? SessionURLOpenerSpy()
    return SessionFeature.Dependencies(
        overlayRequester: overlay,
        openURL: { url in await opener.open(url) }
    )
}

@MainActor
final class JavaScriptDialogHarness {
    let overlay: SessionOverlayRequesterSpy
    var sessionWebView: SessionWebView?

    var webView: WKWebView {
        get throws {
            guard
                let sessionWebView,
                let webView = sessionWebView.subviews.compactMap({ $0 as? WKWebView }).first
            else {
                throw JavaScriptDialogTestError.missingWebView
            }
            return webView
        }
    }

    private let window: UIWindow
    private let fixtureURL: URL
    private var isTornDown = false
    private let disposeBag = DisposeBag()

    init(overlay: SessionOverlayRequesterSpy = SessionOverlayRequesterSpy()) throws {
        self.overlay = overlay
        let sessionWebView = SessionWebView(
            dependencies: makeSessionDependencies(overlay: overlay)
        )
        sessionWebView.frame = CGRect(x: 0, y: 0, width: 390, height: 760)
        self.sessionWebView = sessionWebView

        window = UIWindow(frame: sessionWebView.bounds)
        let viewController = UIViewController()
        viewController.view.addSubview(sessionWebView)
        window.rootViewController = viewController
        window.isHidden = false

        fixtureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dialog-\(UUID().uuidString).html")
        try Data("<html><body>Dialog fixture</body></html>".utf8).write(to: fixtureURL)

        let loaded = XCTestExpectation(description: "Dialog fixture loaded")
        sessionWebView.rx.navigationFinished
            .asObservable()
            .take(1)
            .subscribe(onNext: { loaded.fulfill() })
            .disposed(by: disposeBag)
        sessionWebView.load(url: fixtureURL)

        guard XCTWaiter.wait(for: [loaded], timeout: 10) == .completed else {
            throw JavaScriptDialogTestError.loadTimedOut
        }
    }

    func evaluateJavaScript(
        _ script: String,
        completion: @escaping (Any?, Error?) -> Void
    ) throws {
        try webView.evaluateJavaScript(script) { value, error in
            completion(value, error)
        }
    }

    func releaseSessionWebView() throws -> WKWebView {
        let retainedWebView = try webView
        retainedWebView.removeFromSuperview()
        sessionWebView?.removeFromSuperview()
        sessionWebView = nil
        return retainedWebView
    }

    func tearDown() {
        guard !isTornDown else {
            return
        }
        isTornDown = true
        sessionWebView?.removeFromSuperview()
        sessionWebView = nil
        window.rootViewController = nil
        window.isHidden = true
        try? FileManager.default.removeItem(at: fixtureURL)
    }
}

enum JavaScriptDialogTestError: Error {
    case missingWebView
    case loadTimedOut
}

func makeImmediateAlertFixture() throws -> URL {
    let fixtureURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("session-end-\(UUID().uuidString).html")
    let html = """
    <html><body><script>
        alert('Pending');
    </script></body></html>
    """
    try Data(html.utf8).write(to: fixtureURL)
    return fixtureURL
}

@MainActor
func waitUntil(
    timeout: TimeInterval = 1,
    condition: () -> Bool
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if condition() {
            return true
        }
        await Task.yield()
    }

    return condition()
}
