//
//  SessionWebNavigationFailure.swift
//  Clipy
//
//  Created by 박민서 on 5/19/26.
//

import Foundation

/// WebKit navigation 실패를 Session 안에서 다루기 쉬운 이벤트로 나눕니다.
enum SessionWebNavigationFailure: Error, Equatable {
    case committed(SessionWebNavigationFailureContext)
    case provisional(SessionWebNavigationFailureContext)
}

/// WebKit error에서 비교와 logging에 필요한 값만 보관합니다.
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
