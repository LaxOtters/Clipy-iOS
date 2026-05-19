//
//  SessionBrowserState.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

/// Session WebView가 화면에 알려야 하는 URL, loading, back 가능 상태입니다.
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
