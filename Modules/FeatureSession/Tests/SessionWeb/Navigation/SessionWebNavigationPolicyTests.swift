//
//  SessionWebNavigationPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import XCTest

@testable import FeatureSession

final class SessionWebNavigationPolicyTests: XCTestCase {
    func test_actionPolicy_appliesFrameAndScheme_beforeDownloadIntent() throws {
        let externalURL = try XCTUnwrap(URL(string: "sample-app://checkout"))

        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: externalURL,
                frame: .main,
                shouldPerformDownload: true
            ),
            .confirmExternalOpen(externalURL)
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: externalURL,
                frame: .newWindow,
                shouldPerformDownload: true
            ),
            .confirmExternalOpen(externalURL)
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: externalURL,
                frame: .subframe,
                shouldPerformDownload: true
            ),
            .cancel
        )
    }

    func test_actionPolicy_handlesHTTPDownload_byFrameAndHostEligibility() throws {
        let eligibleURLs = try [
            "https://example.com/file",
            "http://localhost/file",
            "https://intranet/file",
            "https://127.0.0.1/file",
            "https://user:password@example.com/file"
        ].map { try XCTUnwrap(URL(string: $0)) }
        let ineligibleURL = try XCTUnwrap(URL(string: "https:file"))

        for eligibleURL in eligibleURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: eligibleURL,
                    frame: .main,
                    shouldPerformDownload: true
                ),
                .confirmBrowserFallback(eligibleURL)
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: eligibleURL,
                    frame: .newWindow,
                    shouldPerformDownload: true
                ),
                .confirmBrowserFallback(eligibleURL)
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: eligibleURL,
                    frame: .subframe,
                    shouldPerformDownload: true
                ),
                .cancel
            )
        }
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: ineligibleURL,
                frame: .main,
                shouldPerformDownload: true
            ),
            .showUnsupportedDownloadMessage
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: ineligibleURL,
                frame: .newWindow,
                shouldPerformDownload: true
            ),
            .showUnsupportedDownloadMessage
        )
    }

    func test_actionPolicy_keepsOrdinaryHTTPNavigationAndPassiveInternalSchemesInsideWebKit() throws {
        let webURL = try XCTUnwrap(URL(string: "HTTPS://example.com/page"))
        let passiveInternalURLs = try [
            "about:blank",
            "javascript:void(0)"
        ].map { try XCTUnwrap(URL(string: $0)) }

        for frame in [
            SessionWebNavigationPolicy.Frame.main,
            .newWindow,
            .subframe
        ] {
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: webURL,
                    frame: frame,
                    shouldPerformDownload: false
                ),
                .allow
            )
        }

        for url in passiveInternalURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .main,
                    shouldPerformDownload: true
                ),
                .allow
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .newWindow,
                    shouldPerformDownload: true
                ),
                .cancel
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .subframe,
                    shouldPerformDownload: true
                ),
                .allow
            )
        }
    }

    func test_actionPolicy_rejectsLocalContentDownloadIntent_withoutUserVisibleSubframeEffect() throws {
        let localContentURLs = try [
            "blob:https://example.com/id",
            "data:text/plain,a",
            "file:///tmp/a"
        ].map { try XCTUnwrap(URL(string: $0)) }

        for url in localContentURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .main,
                    shouldPerformDownload: true
                ),
                .showUnsupportedDownloadMessage
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .newWindow,
                    shouldPerformDownload: true
                ),
                .showUnsupportedDownloadMessage
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .subframe,
                    shouldPerformDownload: true
                ),
                .cancel
            )
        }
    }

    func test_actionPolicy_keepsLocalContentNavigationNative_withoutDownloadIntent() throws {
        let localContentURLs = try [
            "blob:https://example.com/id",
            "data:text/plain,a",
            "file:///tmp/a"
        ].map { try XCTUnwrap(URL(string: $0)) }

        for url in localContentURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .main,
                    shouldPerformDownload: false
                ),
                .allow
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .newWindow,
                    shouldPerformDownload: false
                ),
                .cancel
            )
            XCTAssertEqual(
                SessionWebNavigationPolicy.action(
                    url: url,
                    frame: .subframe,
                    shouldPerformDownload: false
                ),
                .allow
            )
        }
    }

    func test_actionPolicy_handlesMissingScheme_byFrame() {
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: URL(string: "relative/path"),
                frame: .main,
                shouldPerformDownload: false
            ),
            .allow
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: nil,
                frame: .newWindow,
                shouldPerformDownload: false
            ),
            .cancel
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.action(
                url: nil,
                frame: .subframe,
                shouldPerformDownload: false
            ),
            .allow
        )
    }

}
