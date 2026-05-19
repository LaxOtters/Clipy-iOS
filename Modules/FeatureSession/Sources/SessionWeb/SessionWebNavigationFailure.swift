//
//  SessionWebNavigationFailure.swift
//  Clipy
//
//  Created by 박민서 on 5/19/26.
//

import Foundation

/// Session WebView navigation 실패를 후속 fallback이나 logging에서 다루게 합니다.
enum SessionWebNavigationFailure: Error, Equatable {
    case committed(SessionWebNavigationFailureContext)
    case provisional(SessionWebNavigationFailureContext)
}

/// WebKit error를 비교 가능한 navigation failure 값으로 보관합니다.
struct SessionWebNavigationFailureContext: Equatable {
    let domain: String
    let code: Int
    let message: String

    init(error: Error) {
        let error = error as NSError
        domain = error.domain
        code = error.code
        message = error.localizedDescription
    }
}
