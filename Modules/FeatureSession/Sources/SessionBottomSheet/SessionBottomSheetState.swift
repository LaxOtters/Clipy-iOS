//
//  SessionBottomSheetState.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

/// Session Bottom Sheet가 snap될 수 있는 높이 상태입니다.
enum SessionBottomSheetState: Equatable, CaseIterable {
    /// WebView에 집중할 수 있게 sheet를 완전히 내린 상태입니다.
    case hidden
    /// grabber와 URL bar가 들어갈 최소 chrome 높이입니다.
    case minimized
    /// URL bar 아래로 item preview가 함께 보이는 기본 탐색 높이입니다.
    case peek
    /// 비교/결정 컨텐츠를 보기 위해 status bar 아래까지 sheet를 확장한 높이입니다.
    case expanded
}
