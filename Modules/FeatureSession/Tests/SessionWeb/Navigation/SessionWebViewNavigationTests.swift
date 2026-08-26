//
//  SessionWebViewNavigationTests.swift
//  Clipy
//
//  Created by 박민서 on 8/10/26.
//

import UIKit
import WebKit
import XCTest

import RxSwift

@testable import FeatureSession

final class SessionWebViewNavigationTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func test_navigationDelegate_preservesCommittedAndProvisionalFailureKinds() {
        let sut = SessionWebView(overlayRequester: SessionOverlayRequesterSpy())
        let committedError = NSError(domain: "committed", code: 41)
        let provisionalError = NSError(domain: "provisional", code: 42)
        var failures: [SessionWebNavigationFailure] = []

        sut.rx.navigationFailure
            .emit(onNext: { failures.append($0) })
            .disposed(by: disposeBag)

        sut.webView(WKWebView(), didFail: nil, withError: committedError)
        sut.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: provisionalError)

        XCTAssertEqual(
            failures,
            [
                .committed(SessionWebNavigationFailureContext(error: committedError)),
                .provisional(SessionWebNavigationFailureContext(error: provisionalError))
            ]
        )
    }

    func test_load_emitsEffectiveURLProjection_beforeRealNavigationFinishes() throws {
        let harness = try makeHistoryHarness()
        var states: [SessionBrowserState] = []

        harness.webView.rx.browserState
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        try waitForNavigationFinish(
            on: harness.webView,
            step: "initial local page load"
        ) {
            harness.webView.load(url: harness.firstURL)
        }

        XCTAssertEqual(states.first?.urlDisplayText, harness.firstDisplayText)
        XCTAssertEqual(harness.webView.currentURL, harness.firstURL)
    }

    func test_goBackWithoutHistory_keepsCurrentPageAndControls() throws {
        let harness = try makeHistoryHarness()
        try load(harness.firstURL, on: harness.webView, step: "load single history entry")
        _ = try waitForBrowserState(
            on: harness.webView,
            step: "single entry controls before back"
        ) {
            $0.urlDisplayText == harness.firstDisplayText && $0.canReload
        }

        harness.webView.goBack()

        let state = try waitForBrowserState(on: harness.webView, step: "controls after unsupported back") {
            $0.urlDisplayText == harness.firstDisplayText && $0.canReload
        }
        XCTAssertEqual(harness.webView.currentURL, harness.firstURL)
        XCTAssertFalse(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
    }

    func test_goForwardWithoutHistory_keepsCurrentPageAndControls() throws {
        let harness = try makeHistoryHarness()
        try load(harness.firstURL, on: harness.webView, step: "load single history entry")
        _ = try waitForBrowserState(
            on: harness.webView,
            step: "single entry controls before forward"
        ) {
            $0.urlDisplayText == harness.firstDisplayText && $0.canReload
        }

        harness.webView.goForward()

        let state = try waitForBrowserState(on: harness.webView, step: "controls after unsupported forward") {
            $0.urlDisplayText == harness.firstDisplayText && $0.canReload
        }
        XCTAssertEqual(harness.webView.currentURL, harness.firstURL)
        XCTAssertFalse(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
    }

    func test_goBackWithHistory_reachesPreviousPageAndUpdatesControls() throws {
        let harness = try makeHistoryHarness()
        try load(harness.firstURL, on: harness.webView, step: "load first history entry")
        try load(harness.secondURL, on: harness.webView, step: "load second history entry")
        _ = try waitForBrowserState(on: harness.webView, step: "back becomes available") {
            $0.canGoBack && $0.urlDisplayText == harness.secondDisplayText
        }

        try waitForNavigationFinish(on: harness.webView, step: "go back") {
            harness.webView.goBack()
        }

        let backState = try waitForBrowserState(on: harness.webView, step: "forward becomes available") {
            $0.canGoForward && $0.urlDisplayText == harness.firstDisplayText
        }
        XCTAssertEqual(harness.webView.currentURL, harness.firstURL)
        XCTAssertTrue(backState.canReload)
    }

    func test_goForwardWithHistory_reachesNextPageAndUpdatesControls() throws {
        let harness = try makeHistoryHarness()
        try load(harness.firstURL, on: harness.webView, step: "load first history entry")
        try load(harness.secondURL, on: harness.webView, step: "load second history entry")
        _ = try waitForBrowserState(on: harness.webView, step: "back becomes available") {
            $0.canGoBack && $0.urlDisplayText == harness.secondDisplayText
        }
        try waitForNavigationFinish(on: harness.webView, step: "prepare forward history") {
            harness.webView.goBack()
        }
        _ = try waitForBrowserState(on: harness.webView, step: "forward becomes available") {
            $0.canGoForward && $0.urlDisplayText == harness.firstDisplayText
        }

        try waitForNavigationFinish(on: harness.webView, step: "go forward") {
            harness.webView.goForward()
        }

        let forwardState = try waitForBrowserState(on: harness.webView, step: "back becomes available again") {
            $0.canGoBack && $0.urlDisplayText == harness.secondDisplayText
        }
        XCTAssertEqual(harness.webView.currentURL, harness.secondURL)
        XCTAssertTrue(forwardState.canReload)
    }

    func test_reload_finishesAtSameURL_withEffectiveControlsAndNoFailure() throws {
        let harness = try makeHistoryHarness()
        var failures: [SessionWebNavigationFailure] = []
        harness.webView.rx.navigationFailure
            .emit(onNext: { failures.append($0) })
            .disposed(by: disposeBag)
        try load(harness.firstURL, on: harness.webView, step: "load first history entry")
        try load(harness.secondURL, on: harness.webView, step: "load reload fixture")
        _ = try waitForBrowserState(on: harness.webView, step: "reload fixture controls") {
            $0.urlDisplayText == harness.secondDisplayText && $0.canGoBack && $0.canReload
        }

        try waitForNavigationFinish(on: harness.webView, step: "reload fixture") {
            harness.webView.reload()
        }

        let state = try waitForBrowserState(on: harness.webView, step: "reload controls settle") {
            $0.urlDisplayText == harness.secondDisplayText && $0.canGoBack && $0.canReload
        }
        XCTAssertEqual(harness.webView.currentURL, harness.secondURL)
        XCTAssertTrue(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
        XCTAssertTrue(failures.isEmpty)
    }

    private func makeHistoryHarness() throws -> SessionWebViewHistoryHarness {
        let harness = try SessionWebViewHistoryHarness()
        addTeardownBlock {
            harness.tearDown()
        }
        return harness
    }

    private func load(_ url: URL, on sut: SessionWebView, step: String) throws {
        try waitForNavigationFinish(on: sut, step: step) {
            sut.load(url: url)
        }
    }

    private func waitForNavigationFinish(
        on sut: SessionWebView,
        step: String,
        action: () -> Void
    ) throws {
        let completed = expectation(description: step)
        let disposable = sut.rx.navigationFinished
            .asObservable()
            .take(1)
            .subscribe(onNext: { completed.fulfill() })

        action()
        let result = XCTWaiter.wait(for: [completed], timeout: 10)
        disposable.dispose()

        guard result == .completed else {
            XCTFail("Timed out while waiting for \(step). Current URL: \(String(describing: sut.currentURL))")
            throw StepFailure.timedOut
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
            throw StepFailure.timedOut
        }

        return matchedState
    }
}

private enum StepFailure: Error {
    case timedOut
}

private final class SessionWebViewHistoryHarness {
    let webView = SessionWebView(
        frame: CGRect(x: 0, y: 0, width: 390, height: 760),
        overlayRequester: SessionOverlayRequesterSpy()
    )
    let firstName = "first-\(UUID().uuidString)"
    let secondName = "second-\(UUID().uuidString)"
    let firstURL: URL
    let secondURL: URL

    var firstDisplayText: String { firstURL.absoluteString }
    var secondDisplayText: String { secondURL.absoluteString }

    private let window: UIWindow
    private let fixtureDirectory: URL
    private var isTornDown = false

    init() throws {
        fixtureDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: fixtureDirectory,
            withIntermediateDirectories: true
        )
        firstURL = try Self.writeHTMLFixture(name: firstName, to: fixtureDirectory)
        secondURL = try Self.writeHTMLFixture(name: secondName, to: fixtureDirectory)

        window = UIWindow(frame: webView.bounds)
        let viewController = UIViewController()
        viewController.view.addSubview(webView)
        window.rootViewController = viewController
        window.isHidden = false
    }

    deinit {
        tearDown()
    }

    func tearDown() {
        guard !isTornDown else { return }
        isTornDown = true
        webView.removeFromSuperview()
        window.rootViewController = nil
        window.isHidden = true
        try? FileManager.default.removeItem(at: fixtureDirectory)
    }

    private static func writeHTMLFixture(name: String, to directory: URL) throws -> URL {
        let url = directory.appendingPathComponent("\(name).html")
        let html = "<html><title>\(name)</title><body>\(name)</body></html>"
        try Data(html.utf8).write(to: url)
        return url
    }
}
