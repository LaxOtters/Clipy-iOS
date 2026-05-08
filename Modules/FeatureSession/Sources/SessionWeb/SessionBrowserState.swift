//
//  SessionBrowserState.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation

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
