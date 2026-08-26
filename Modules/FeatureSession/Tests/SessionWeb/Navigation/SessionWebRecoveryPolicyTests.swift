//
//  SessionWebRecoveryPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 8/27/26.
//

import XCTest

@testable import FeatureSession

final class SessionWebRecoveryPolicyTests: XCTestCase {
    func test_errorCategory_mapsPublicURLErrorGroups_toRecoveryCopy() {
        assertCategory(.certificate, for: [
            .secureConnectionFailed,
            .serverCertificateHasBadDate,
            .serverCertificateUntrusted,
            .serverCertificateHasUnknownRoot,
            .serverCertificateNotYetValid,
            .clientCertificateRejected,
            .clientCertificateRequired,
            .appTransportSecurityRequiresSecureConnection
        ])
        assertCategory(.networkUnavailable, for: [
            .notConnectedToInternet,
            .internationalRoamingOff,
            .callIsActive,
            .dataNotAllowed
        ])
        assertCategory(.serverConnectivity, for: [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .httpTooManyRedirects,
            .resourceUnavailable,
            .badServerResponse,
            .zeroByteResource,
            .cannotDecodeRawData,
            .cannotDecodeContentData,
            .cannotParseResponse,
            .cannotLoadFromNetwork
        ])
        assertCategory(.unavailable, for: [
            .badURL,
            .unsupportedURL,
            .redirectToNonExistentLocation
        ])

        XCTAssertEqual(category(.cancelled), .cancelled)
        XCTAssertEqual(category(.userAuthenticationRequired), .unexpected)
        XCTAssertEqual(
            SessionWebRecoveryPolicy.category(for: NSError(domain: "Other", code: -1009)),
            .unexpected
        )
    }

    func test_presentation_usesInactiveCancelledMountedAndUsablePagePrecedence() throws {
        let currentURL = try XCTUnwrap(URL(string: "https://example.com/current"))
        let failingURL = try XCTUnwrap(URL(string: "https://example.com/failed"))
        let failure = provisionalFailure(code: .cannotConnectToHost, failingURL: failingURL)

        XCTAssertEqual(
            presentation(
                failure,
                isSessionActive: false,
                hasMountedErrorContent: false,
                currentURL: currentURL,
                currentItemURL: currentURL
            ),
            .none
        )
        XCTAssertEqual(
            presentation(
                provisionalFailure(code: .cancelled, failingURL: failingURL),
                hasMountedErrorContent: true,
                currentURL: currentURL,
                currentItemURL: currentURL
            ),
            .none
        )

        guard case .error = presentation(
            failure,
            hasMountedErrorContent: true,
            currentURL: currentURL,
            currentItemURL: currentURL
        ) else {
            return XCTFail("Mounted recovery content must be replaced by the latest failure.")
        }

        XCTAssertEqual(
            presentation(
                provisionalFailure(code: .serverCertificateUntrusted, failingURL: failingURL),
                hasMountedErrorContent: false,
                currentURL: currentURL,
                currentItemURL: currentURL
            ),
            .snackbar("Couldn't load this page")
        )
    }

    func test_ordinaryFailure_usesURLOnlyForRetry_thenBackOrHome() {
        let failure = committedFailure(code: .timedOut)
        let currentItemURL = URL(string: "https://example.com/history")

        XCTAssertEqual(
            errorContent(
                from: presentation(
                    failure,
                    currentURL: URL(string: "https://example.com/current"),
                    currentItemURL: currentItemURL,
                    canGoBack: true
                )
            ).action,
            .reload
        )
        XCTAssertEqual(
            errorContent(
                from: presentation(
                    failure,
                    currentURL: nil,
                    currentItemURL: currentItemURL,
                    canGoBack: true
                )
            ).action,
            .goBack
        )
        XCTAssertEqual(
            errorContent(
                from: presentation(
                    failure,
                    currentURL: nil,
                    currentItemURL: currentItemURL,
                    canGoBack: false
                )
            ).action,
            .goHome
        )
    }

    func test_certificateFailure_withoutUsablePage_offersBackOrHomeOnly() {
        let failure = provisionalFailure(code: .serverCertificateUntrusted, failingURL: nil)

        let back = errorContent(from: presentation(failure, canGoBack: true))
        XCTAssertEqual(back.title, "This connection isn’t secure")
        XCTAssertEqual(back.actionTitle, "Go back")
        XCTAssertEqual(back.action, .goBack)

        let home = errorContent(from: presentation(failure, canGoBack: false))
        XCTAssertEqual(home.actionTitle, "Go home")
        XCTAssertEqual(home.action, .goHome)
    }

    func test_processTermination_usesURLOrCurrentItem_thenHome() {
        let currentURL = URL(string: "https://example.com/current")

        XCTAssertEqual(
            SessionWebRecoveryPolicy.processTerminationPresentation(
                snapshot: snapshot(currentURL: currentURL)
            ),
            .error(
                .init(
                    title: "This page stopped responding",
                    body: "Reopen the page to continue.",
                    actionTitle: "Reopen page",
                    action: .reopenPage
                )
            )
        )
        XCTAssertEqual(
            errorContent(
                from: SessionWebRecoveryPolicy.processTerminationPresentation(
                    snapshot: snapshot(currentItemURL: currentURL)
                )
            ).action,
            .reopenPage
        )
        XCTAssertEqual(
            errorContent(
                from: SessionWebRecoveryPolicy.processTerminationPresentation(
                    snapshot: snapshot()
                )
            ).action,
            .goHome
        )
        XCTAssertEqual(
            SessionWebRecoveryPolicy.processTerminationPresentation(
                snapshot: snapshot(
                    isSessionActive: false,
                    currentURL: currentURL,
                    currentItemURL: currentURL
                )
            ),
            .none
        )
    }

    private func presentation(
        _ failure: SessionWebNavigationFailure,
        isSessionActive: Bool = true,
        hasMountedErrorContent: Bool = false,
        currentURL: URL? = nil,
        currentItemURL: URL? = nil,
        canGoBack: Bool = false
    ) -> SessionWebRecoveryPolicy.Presentation {
        SessionWebRecoveryPolicy.presentation(
            failure: failure,
            snapshot: snapshot(
                isSessionActive: isSessionActive,
                hasMountedErrorContent: hasMountedErrorContent,
                currentURL: currentURL,
                currentItemURL: currentItemURL,
                canGoBack: canGoBack
            )
        )
    }

    private func snapshot(
        isSessionActive: Bool = true,
        hasMountedErrorContent: Bool = false,
        currentURL: URL? = nil,
        currentItemURL: URL? = nil,
        canGoBack: Bool = false
    ) -> SessionWebRecoveryPolicy.Snapshot {
        SessionWebRecoveryPolicy.Snapshot(
            isSessionActive: isSessionActive,
            hasMountedErrorContent: hasMountedErrorContent,
            currentURL: currentURL,
            currentItemURL: currentItemURL,
            canGoBack: canGoBack
        )
    }

    private func errorContent(
        from presentation: SessionWebRecoveryPolicy.Presentation
    ) -> SessionWebRecoveryPolicy.ErrorContent {
        guard case let .error(content) = presentation else {
            XCTFail("Expected error content, got \(presentation).")
            return .init(title: "", body: "", actionTitle: "", action: .goHome)
        }
        return content
    }

    private func assertCategory(
        _ expected: SessionWebRecoveryPolicy.Category,
        for codes: [URLError.Code]
    ) {
        codes.forEach { code in
            XCTAssertEqual(category(code), expected, "Unexpected category for \(code)")
        }
    }

    private func category(_ code: URLError.Code) -> SessionWebRecoveryPolicy.Category {
        SessionWebRecoveryPolicy.category(
            for: NSError(domain: NSURLErrorDomain, code: code.rawValue)
        )
    }

    private func committedFailure(code: URLError.Code) -> SessionWebNavigationFailure {
        .committed(
            SessionWebNavigationFailureContext(
                error: NSError(domain: NSURLErrorDomain, code: code.rawValue)
            )
        )
    }

    private func provisionalFailure(
        code: URLError.Code,
        failingURL: URL?
    ) -> SessionWebNavigationFailure {
        var userInfo: [String: Any] = [:]
        userInfo[NSURLErrorFailingURLErrorKey] = failingURL
        let error = NSError(domain: NSURLErrorDomain, code: code.rawValue, userInfo: userInfo)
        return .provisional(SessionWebNavigationFailureContext(error: error))
    }
}
