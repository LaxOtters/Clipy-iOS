//
//  SessionWebNavigationPolicy.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import Foundation

enum SessionWebNavigationPolicy {
    enum Frame {
        case main
        case newWindow
        case subframe
    }

    enum Action: Equatable {
        case allow
        case cancel
        case confirmExternalOpen(URL)
        case confirmBrowserFallback(URL)
        case showUnsupportedDownloadMessage
    }

    enum Response: Equatable {
        case allow
        case cancel
        case confirmBrowserFallback(URL)
        case showUnsupportedDownloadMessage
    }

    static func action(
        url: URL?,
        frame: Frame,
        shouldPerformDownload: Bool
    ) -> Action {
        guard let scheme = url?.scheme?.lowercased(), !scheme.isEmpty else {
            return frame == .newWindow ? .cancel : .allow
        }

        if isWebScheme(scheme) {
            guard shouldPerformDownload else {
                return .allow
            }
            guard frame != .subframe else {
                return .cancel
            }
            guard let url, isBrowserFallbackEligible(url) else {
                return .showUnsupportedDownloadMessage
            }
            return .confirmBrowserFallback(url)
        }

        if isWebKitInternalScheme(scheme) {
            return frame == .newWindow ? .cancel : .allow
        }

        guard frame != .subframe, let url else {
            return .cancel
        }
        return .confirmExternalOpen(url)
    }

    static func response(
        url: URL?,
        isForMainFrame: Bool,
        canShowMIMEType: Bool
    ) -> Response {
        guard !canShowMIMEType else {
            return .allow
        }
        guard isForMainFrame else {
            return .cancel
        }
        guard let url, isBrowserFallbackEligible(url) else {
            return .showUnsupportedDownloadMessage
        }
        return .confirmBrowserFallback(url)
    }

    static func shouldLoadNewWindowRequestInMain(
        _ url: URL?,
        shouldPerformDownload: Bool
    ) -> Bool {
        guard !shouldPerformDownload, let scheme = url?.scheme?.lowercased() else {
            return false
        }
        return isWebScheme(scheme)
    }

    private static func isWebScheme(_ scheme: String) -> Bool {
        scheme == "http" || scheme == "https"
    }

    private static func isWebKitInternalScheme(_ scheme: String) -> Bool {
        ["about", "javascript", "blob", "data", "file"].contains(scheme)
    }

    private static func isBrowserFallbackEligible(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), isWebScheme(scheme) else {
            return false
        }
        guard let host = url.host else {
            return false
        }
        return !host.isEmpty
    }
}
