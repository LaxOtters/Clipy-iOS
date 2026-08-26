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

        if isPassiveWebKitInternalScheme(scheme) {
            return frame == .newWindow ? .cancel : .allow
        }

        if isLocalContentScheme(scheme) {
            guard shouldPerformDownload else {
                return frame == .newWindow ? .cancel : .allow
            }
            return frame == .subframe ? .cancel : .showUnsupportedDownloadMessage
        }

        guard frame != .subframe, let url else {
            return .cancel
        }
        return .confirmExternalOpen(url)
    }

    static func response(
        isForMainFrame: Bool,
        canShowMIMEType: Bool,
        contentDisposition: String?
    ) -> Response {
        guard isAttachment(contentDisposition) || !canShowMIMEType else {
            return .allow
        }
        return isForMainFrame ? .showUnsupportedDownloadMessage : .cancel
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

    private static func isPassiveWebKitInternalScheme(_ scheme: String) -> Bool {
        scheme == "about" || scheme == "javascript"
    }

    private static func isLocalContentScheme(_ scheme: String) -> Bool {
        scheme == "blob" || scheme == "data" || scheme == "file"
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

    private static func isAttachment(_ contentDisposition: String?) -> Bool {
        contentDisposition?
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == "attachment"
    }
}
