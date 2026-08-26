//
//  SessionWebRecoveryPolicy.swift
//  Clipy
//
//  Created by 박민서 on 8/27/26.
//

import Foundation

enum SessionWebRecoveryPolicy {
    enum Category: Equatable {
        case cancelled
        case certificate
        case networkUnavailable
        case serverConnectivity
        case unavailable
        case unexpected
    }

    enum Action: Equatable {
        case reload
        case goBack
        case goHome
        case reopenPage
    }

    struct ErrorContent: Equatable {
        let title: String
        let body: String
        let actionTitle: String
        let action: Action
    }

    enum Presentation: Equatable {
        case none
        case snackbar(String)
        case error(ErrorContent)
    }

    /// recovery 표시를 고르는 시점의 WebView 상태입니다. navigation 사이에 저장해 두지 않습니다.
    struct Snapshot: Equatable {
        let isSessionActive: Bool
        let hasMountedErrorContent: Bool
        let currentURL: URL?
        let currentItemURL: URL?
        let canGoBack: Bool
    }

    static func category(for error: NSError) -> Category {
        guard error.domain == NSURLErrorDomain else {
            return .unexpected
        }

        switch URLError.Code(rawValue: error.code) {
        case .cancelled:
            return .cancelled
        case .secureConnectionFailed,
             .serverCertificateHasBadDate,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid,
             .clientCertificateRejected,
             .clientCertificateRequired,
             .appTransportSecurityRequiresSecureConnection:
            return .certificate
        case .notConnectedToInternet,
             .internationalRoamingOff,
             .callIsActive,
             .dataNotAllowed:
            return .networkUnavailable
        case .timedOut,
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
             .cannotLoadFromNetwork:
            return .serverConnectivity
        case .badURL,
             .unsupportedURL,
             .redirectToNonExistentLocation:
            return .unavailable
        default:
            return .unexpected
        }
    }

    static func presentation(
        failure: SessionWebNavigationFailure,
        snapshot: Snapshot
    ) -> Presentation {
        guard snapshot.isSessionActive else {
            return .none
        }

        let context: SessionWebNavigationFailureContext
        let isProvisional: Bool
        switch failure {
        case let .committed(value):
            context = value
            isProvisional = false
        case let .provisional(value):
            context = value
            isProvisional = true
        }

        let category = category(for: context.error)
        guard category != .cancelled else {
            return .none
        }

        if snapshot.hasMountedErrorContent {
            return .error(
                errorContent(
                    category: category,
                    canReload: snapshot.currentURL != nil,
                    canGoBack: snapshot.canGoBack
                )
            )
        }

        if isProvisional,
           let failingURL = context.failingURL,
           let currentItemURL = snapshot.currentItemURL,
           currentItemURL != failingURL {
            return .snackbar("Couldn't load this page")
        }

        return .error(
            errorContent(
                category: category,
                canReload: snapshot.currentURL != nil,
                canGoBack: snapshot.canGoBack
            )
        )
    }

    static func processTerminationPresentation(snapshot: Snapshot) -> Presentation {
        guard snapshot.isSessionActive else {
            return .none
        }

        let canReopen = snapshot.currentURL != nil || snapshot.currentItemURL != nil
        return .error(
            ErrorContent(
                title: "This page stopped responding",
                body: "Reopen the page to continue.",
                actionTitle: canReopen ? "Reopen page" : "Go home",
                action: canReopen ? .reopenPage : .goHome
            )
        )
    }

    private static func errorContent(
        category: Category,
        canReload: Bool,
        canGoBack: Bool
    ) -> ErrorContent {
        let fallbackAction: Action = canGoBack ? .goBack : .goHome
        let fallbackTitle = canGoBack ? "Go back" : "Go home"

        switch category {
        case .cancelled:
            assertionFailure("Cancelled navigation does not present error content.")
            return unexpectedErrorContent(
                canReload: canReload,
                fallbackTitle: fallbackTitle,
                fallbackAction: fallbackAction
            )
        case .certificate:
            return ErrorContent(
                title: "This connection isn’t secure",
                body: "The site’s security certificate couldn’t be verified.",
                actionTitle: fallbackTitle,
                action: fallbackAction
            )
        case .networkUnavailable:
            return retryableErrorContent(
                title: "No internet connection",
                body: "Check your network connection and try again.",
                canReload: canReload,
                fallbackTitle: fallbackTitle,
                fallbackAction: fallbackAction
            )
        case .serverConnectivity:
            return retryableErrorContent(
                title: "Something went wrong on this site",
                body: "Please try again in a few moments.",
                canReload: canReload,
                fallbackTitle: fallbackTitle,
                fallbackAction: fallbackAction
            )
        case .unavailable:
            return ErrorContent(
                title: "This page can't be opened",
                body: "The page may be unavailable or unsupported.",
                actionTitle: fallbackTitle,
                action: fallbackAction
            )
        case .unexpected:
            return unexpectedErrorContent(
                canReload: canReload,
                fallbackTitle: fallbackTitle,
                fallbackAction: fallbackAction
            )
        }
    }

    private static func unexpectedErrorContent(
        canReload: Bool,
        fallbackTitle: String,
        fallbackAction: Action
    ) -> ErrorContent {
        retryableErrorContent(
            title: "Couldn’t load this page",
            body: "An unexpected error occurred while loading this page.",
            canReload: canReload,
            fallbackTitle: fallbackTitle,
            fallbackAction: fallbackAction
        )
    }

    private static func retryableErrorContent(
        title: String,
        body: String,
        canReload: Bool,
        fallbackTitle: String,
        fallbackAction: Action
    ) -> ErrorContent {
        ErrorContent(
            title: title,
            body: body,
            actionTitle: canReload ? "Try again" : fallbackTitle,
            action: canReload ? .reload : fallbackAction
        )
    }
}
