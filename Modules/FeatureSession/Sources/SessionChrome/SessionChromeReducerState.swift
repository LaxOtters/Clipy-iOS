//
//  SessionChromeReducerState.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// chrome presentation과 현재 interaction 소유권을 같이 넘겨 입력 충돌을 줄입니다.
struct SessionChromeReducerState: Equatable {
    var presentation: SessionChromeState
    var interaction: SessionChromeInteraction

    static let newSession = SessionChromeReducerState(
        presentation: .newSession,
        interaction: .idle
    )
}
