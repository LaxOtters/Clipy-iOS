//
//  SessionBrowserState.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

/// WebView wrapper 밖에서 화면이 알아야 할 browser 상태만 남깁니다.
struct SessionBrowserState: Equatable {
    let currentURL: URL?
    let isLoading: Bool
    let canGoBack: Bool

    static let empty = SessionBrowserState(
        currentURL: nil,
        isLoading: false,
        canGoBack: false
    )
}
