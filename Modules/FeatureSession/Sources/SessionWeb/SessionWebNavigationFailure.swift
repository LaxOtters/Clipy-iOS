//
//  SessionWebNavigationFailure.swift
//  Clipy
//
//  Created by 박민서 on 5/19/26.
//

import Foundation

enum SessionWebNavigationFailure: Error, Equatable {
    case committed(SessionWebNavigationFailureContext)
    case provisional(SessionWebNavigationFailureContext)
}

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
