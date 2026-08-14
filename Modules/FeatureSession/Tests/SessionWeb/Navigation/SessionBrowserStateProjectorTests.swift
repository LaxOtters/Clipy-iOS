//
//  SessionBrowserStateProjectorTests.swift
//  Clipy
//
//  Created by 박민서 on 8/10/26.
//

import XCTest

@testable import FeatureSession

final class SessionBrowserStateProjectorTests: XCTestCase {
    func test_projectingRequestedURL_displaysDomain_beforeWebKitHasCurrentURL() {
        var sut = SessionBrowserStateProjector()

        let state = sut.project(
            snapshot: snapshot(url: nil),
            requestedURL: URL(string: "https://WWW.example.com/products/1?color=navy")!
        )

        XCTAssertEqual(
            state,
            SessionBrowserState(
                urlDisplayText: "example.com",
                canGoBack: false,
                canGoForward: false,
                canReload: false
            )
        )
    }

    func test_projectingURL_removesOneLeadingMixedCaseWWW_only() {
        var sut = SessionBrowserStateProjector()

        let state = sut.project(
            snapshot: snapshot(
                url: URL(string: "https://WwW.www.example.com/path")!
            )
        )

        XCTAssertEqual(state.urlDisplayText, "www.example.com")
    }

    func test_projectingHostlessURL_displaysOriginalURL() {
        var sut = SessionBrowserStateProjector()
        let url = URL(string: "about:blank")!

        let state = sut.project(snapshot: snapshot(url: url))

        XCTAssertEqual(state.urlDisplayText, url.absoluteString)
    }

    func test_projectingNilURL_keepsLastDisplayAndCurrentHistory_disablingReloadOnly() {
        var sut = SessionBrowserStateProjector()
        _ = sut.project(
            snapshot: snapshot(url: URL(string: "https://example.com/path")!)
        )

        let state = sut.project(
            snapshot: snapshot(url: nil, canGoBack: true, canGoForward: true)
        )

        XCTAssertEqual(
            state,
            SessionBrowserState(
                urlDisplayText: "example.com",
                canGoBack: true,
                canGoForward: true,
                canReload: false
            )
        )
    }

    private func snapshot(
        url: URL?,
        canGoBack: Bool = false,
        canGoForward: Bool = false
    ) -> SessionBrowserSnapshot {
        SessionBrowserSnapshot(
            url: url,
            canGoBack: canGoBack,
            canGoForward: canGoForward
        )
    }
}
