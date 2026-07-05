//
//  SessionChromeReducerState.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// 지금 화면에 보이는 chrome 상태와 진행 중인 사용자 조작을 함께 들고 갑니다.
/// 둘을 같이 봐야 scroll 중 tap처럼 겹쳐 들어온 입력을 자연스럽게 막을 수 있습니다.
struct SessionChromeReducerState: Equatable {
    var presentation: SessionChromeState
    var interaction: SessionChromeInteraction

    static let newSession = SessionChromeReducerState(
        presentation: .newSession,
        interaction: .idle
    )
}
