//
//  SessionBrowserState.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

/// Bottom Sheet의 브라우저 컨트롤 영역에 표시할 값입니다.
struct SessionBrowserState: Equatable {
    let urlDisplayText: String
    let canGoBack: Bool
    let canGoForward: Bool
    let canReload: Bool
}

struct SessionBrowserSnapshot: Equatable {
    let url: URL?
    let canGoBack: Bool
    let canGoForward: Bool
}

struct SessionBrowserStateProjector {
    private var lastURLDisplayText = ""

    mutating func project(
        snapshot: SessionBrowserSnapshot,
        requestedURL: URL? = nil
    ) -> SessionBrowserState {
        if let displayURL = requestedURL ?? snapshot.url {
            lastURLDisplayText = Self.displayText(for: displayURL)
        }

        return SessionBrowserState(
            urlDisplayText: lastURLDisplayText,
            canGoBack: snapshot.canGoBack,
            canGoForward: snapshot.canGoForward,
            canReload: snapshot.url != nil
        )
    }

    private static func displayText(for url: URL) -> String {
        guard let host = url.host else {
            return url.absoluteString
        }

        guard host.lowercased().hasPrefix("www.") else {
            return host
        }

        return String(host.dropFirst(4))
    }
}
