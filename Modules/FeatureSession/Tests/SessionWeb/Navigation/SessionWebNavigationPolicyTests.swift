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
        let eligibleURL = try XCTUnwrap(URL(string: "https://example.com/file"))
        let ineligibleURL = try XCTUnwrap(URL(string: "https:file"))

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

    func test_actionPolicy_keepsOrdinaryHTTPNavigationAndInternalSchemesInsideWebKit() throws {
        let webURL = try XCTUnwrap(URL(string: "HTTPS://example.com/page"))
        let internalURLs = try [
            "about:blank",
            "javascript:void(0)",
            "blob:https://example.com/id",
            "data:text/plain,a",
            "file:///tmp/a"
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

        for url in internalURLs {
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

    func test_responsePolicy_allowsDisplayableContent_andSilencesUnsupportedSubframes() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/attachment"))

        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                url: url,
                isForMainFrame: true,
                canShowMIMEType: true
            ),
            .allow
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                url: url,
                isForMainFrame: false,
                canShowMIMEType: false
            ),
            .cancel
        )
    }

    func test_responsePolicy_usesFinalMainFrameURL_forBrowserFallbackEligibility() throws {
        let eligibleURLs = try [
            "https://example.com/file",
            "http://localhost/file",
            "https://intranet/file",
            "https://127.0.0.1/file",
            "https://user:password@example.com/file"
        ].map { try XCTUnwrap(URL(string: $0)) }
        let ineligibleURLs = try [
            "https:file",
            "blob:https://example.com/id",
            "file:///tmp/file"
        ].map { try XCTUnwrap(URL(string: $0)) }

        for url in eligibleURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.response(
                    url: url,
                    isForMainFrame: true,
                    canShowMIMEType: false
                ),
                .confirmBrowserFallback(url)
            )
        }

        for url in ineligibleURLs {
            XCTAssertEqual(
                SessionWebNavigationPolicy.response(
                    url: url,
                    isForMainFrame: true,
                    canShowMIMEType: false
                ),
                .showUnsupportedDownloadMessage
            )
        }
    }
}
